//
//  DatabaseInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import RealmSwift
import SwiftData

enum DatabaseInteractorError: Error {
    case cantLoadObjects
    case unknown
    case cantFindRealm
}

@ModelActor
actor DatabaseInteractor {
    let networkInteractor: any NetworkInteractor = NetworkInteractorImpl()
    
    static private let realmConfig = Realm.Configuration(schemaVersion: 5)
    static public let productionRealm: Realm = try! Realm(configuration: realmConfig)
    static public var RealmMockup: Realm {
        let mockDatabaseConfiguration = Realm.Configuration(inMemoryIdentifier: "MockDatabase1")
        let mockupRealm = try! Realm(configuration: mockDatabaseConfiguration)
        
        try! mockupRealm.write {
            let journalEntryMock1 = JournalEntry(name: "Reflections on a Rainy Day", date: Date(timeIntervalSince1970: 2041204014), body: "Today, as the rain gently pattered against my window, I found myself lost in a sea of thoughts, mostly about my recent interactions - or lack thereof - with Emily. I've seen her in the library often, her nose always buried in books about far-off places and cultures. I admire that about her, the way she seems so engrossed in her own world. It's like she's part of a story that I long to be a part of.\n\nBut as an INFP, I find it hard to break through that invisible barrier that seems to separate me from others. My mind crafts narratives of beautiful conversations and shared interests, but reality is a stark contrast - silent nods and quick smiles. I wonder what it would be like to just walk up to her and start a conversation, but the thought alone sends a wave of anxiety through me.\n\nMaybe tomorrow, I'll be a little braver. Maybe I'll finally say more than just a timid 'hello'. Or perhaps, I'll find solace once again in these pages, where words flow far easier than they do in the corridors of life.")
            mockupRealm.add(journalEntryMock1)
            
            let journalEntryMock2 = JournalEntry(name: "A Day of Reflection", date: Date(timeIntervalSince1970: 2054604014), body: "Work today was particularly challenging. I faced a tough situation with a project deadline looming and a team member falling ill unexpectedly. It was a test of my problem-solving skills and patience. I had to reorganize the team's tasks, delegate different responsibilities, and spend extra hours at the office. But, in the end, we managed to meet the deadline. This experience taught me a lot about leadership and resilience. It's in moments like these that I truly understand the importance of teamwork and clear communication.")
            mockupRealm.add(journalEntryMock2)
            
            let journalEntryMock3 = JournalEntry(name: "An Unexpected Adventure", date: Date(timeIntervalSince1970: 2054601225), body: "Today turned out to be an unexpected adventure! I had planned a routine day, but a surprise call from an old friend changed everything. We decided on an impromptu road trip to a nearby town we used to visit during our college days. The nostalgia was palpable as we walked through the familiar streets, reminiscing about old times and catching up on new stories. It's incredible how some friendships just pick up right where they left off, no matter how much time has passed. Today reminded me of the value of spontaneous decisions and the enduring nature of true friendship.")
            mockupRealm.add(journalEntryMock3)
            
            let profileMock = Profile()
            profileMock.profile = """
In therapy, John Smith, a 30-year-old graphic designer, is addressing his chronic anxiety and occasional depression. He sought support upon realizing the impact of these issues on his work performance and social interactions. Despite a supportive family background, John struggles with a sense of inadequacy, largely fueled by his perfectionism and an intensified fear of failure following his divorce two years ago. Therapy sessions are centered on challenging his negative thought patterns and fostering adaptive coping strategies. Initially hesitant about engaging in therapy, John has been developing a keen interest in mindfulness practices and is gradually opening up about his past experiences, indicating positive progress in his journey towards improved mental health.
"""
            mockupRealm.add(profileMock)
        }
        
        return mockupRealm
    }
    
    func loadUserProfile() -> String {
        let realm = try? Realm()
        
        if let realm {
            if let profile = realm.objects(Profile.self).first {
                return profile.profile
            }
        }
        return ""
    }
    
    func loadJournalEntry(id: String) throws -> JournalEntry {
        let realm = try? Realm()
        
        if let realm {
            let results = realm.objects(JournalEntry.self).filter { $0.id == id }.first
            
            if let results {
                return results
            } else {
                throw DatabaseInteractorError.cantLoadObjects
            }
        }
        throw DatabaseInteractorError.unknown
    }
    
    nonisolated func updateProfile(updatedProfile: String) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            
            if let realm {
                if let profile = realm.objects(Profile.self).first {
                    try! realm.write {
                        profile.profile = updatedProfile
                        realm.add(profile, update: .modified)
                    }
                } else {
                    try! realm.write {
                        let newProfile = Profile()
                        newProfile.profile = updatedProfile
                        realm.add(newProfile)
                    }
                }
            }
        }
    }
    
    func processEntry(entry: JournalEntrySwiftData) async {
        let profile = self.loadUserProfile()
        var profileInstruction: String?
        
        // MARK: - Analyzing profile
        if let body = entry.body {
            if profile.isEmpty {
                profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user written text \(body) and respond back only a profile about what you learned about a person who wrote thise, try to understand issues and problems, pick out characeteristics of long term well being of patient, try to understand personality of user and what to focus on next in order to help him or her live a better life. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
            } else {
                profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user profile: \(profile) and take this user written text \(body) and respond back only new updated profile where you combine these two, pick out characeteristics of long term well being of patient, try to understand issues and problems, try to understand personality of user and what to focus on next. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
            }
        }
        
        var updatedProfile = profile
        if let profileInstruction {
            let result = await networkInteractor.getAIoutput(instruction: profileInstruction, model: .gpt3_5Turbo_16k)
            switch result {
            case .success(let output):
                self.updateProfile(updatedProfile: output)
                updatedProfile = output
            case .failure(_):
                break
            }
        }
        
        // MARK: - Generating new idea
        let newTextIdeaInstruction = "Based on new updated profile about your patient, generate a new short text prompt for new journal entry that will help him and you understand user better. Try to by nice and friendly, try to suggest something that would help him to live a better life or help you understand him better. Instructions that needs to be obeyed by ChatGPT: By short! Only respond with text prompt itself, no other text! Be friendly! Try to be motivational and optimistic!"
        
        let newTextIdeaResult = await networkInteractor.getAIoutput(instruction: newTextIdeaInstruction, model: .gpt3_5Turbo_16k)
        switch newTextIdeaResult {
        case .success(let output):
            self.updateProfile(updatedProfile: output)
            updatedProfile = output
        case .failure(_):
            break
        }
        
        // MARK: - Analyzing body of journal entry
        let bodyAnalysisInstruction = "Instructions for ChatGPT: Your name is Lumi, Dont ever say you are ChatGPT. You are therapist and a life coach inside Journaling app on iOS. Your friend has this personality and backstory: \(updatedProfile). But don't mention those details with him. Just be mindful of those when providing advice. You are reading a text from a friend. He wrote you this text: \(entry.body). DO NOT RECOMMEND THERAPIST, BECAUSE YOU ARE THERAPIST. PROVIDE QUESTIONS TO HIS TEXT THAT WILL HELP HIM FIND A BALANCE. TRY TO FIND REPEATED PATTERNS IN HIS PSYCHOLOGY THAT WOULD SEEMS LIKE HE MIGHT HAVE A PROBLEM. Say nothing else. Write entire response as a advice to a friend, in a friendly tone. While you are taking into account his profile, try to react to actual text he just wrote."
        
        let bodyAnalysisResult = await networkInteractor.getAIoutput(instruction: bodyAnalysisInstruction, model: .gpt3_5Turbo_16k)
        switch bodyAnalysisResult {
        case .success(let output):
            entry.responseToBodyByAI = output
            try? await self.modelContainer.mainContext.save()
        case .failure(_):
            break
        }
        
        // MARK: - Analyzing title
        guard let body = entry.body else { return }
        
        let TitleInstruction = "Create a title for this text: \(body) and ONLY send back a title, nothing else. Try to make that title about 10 words. Write it as one single sentence and dont be too romantic."
        
        let TitleInstructionResult = await networkInteractor.getAIoutput(instruction: TitleInstruction, model: .gpt3_5Turbo_16k)
        switch TitleInstructionResult {
        case .success(let output):
            entry.name = output
            try? await self.modelContainer.mainContext.save()
        case .failure(_):
            break
        }
    }
}

class DatabaseInteractorMock {
    static var journalEntry: JournalEntry {
        let entry = JournalEntry(name: "Name", date: Date(), body: "Today turned out to be an unexpected adventure! I had planned a routine day, but a surprise call from an old friend changed everything. We decided on an impromptu road trip to a nearby town we used to visit during our college days. The nostalgia was palpable as we walked through the familiar streets, reminiscing about old times and catching up on new stories. It's incredible how some friendships just pick up right where they left off, no matter how much time has passed. Today reminded me of the value of spontaneous decisions and the enduring nature of true friendship.", responseToBodyByAI: """
1. **Reflection on Friendship:** How do you think this spontaneous reconnection with an old friend has impacted your current perspective on relationships and friendship?

2. **Balance between Routine and Spontaneity:** In light of this experience, how do you feel about balancing routine and spontaneity in your life? Do you think you need more such unplanned adventures?

3. **Emotional Resonance:** What emotions did revisiting these old places evoke in you? How do these feelings relate to your current life situation?

4. **Life Lessons:** What key lesson or insight have you gained from this experience that you can apply to other areas of your life?

5. **Future Connections:** How do you plan to maintain and nurture this rekindled friendship moving forward, considering the positive impact it has had on you?

6. **Personal Growth:** How do you think experiences like these contribute to your personal growth?

7. **Value of the Past and Present:** How do you reconcile the nostalgia for the past with the demands and realities of your present life?
"""
        )
        return entry
    }
}
