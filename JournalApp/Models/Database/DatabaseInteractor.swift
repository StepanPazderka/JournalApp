//
//  DatabaseInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import SwiftData

enum DatabaseInteractorError: Error {
    case cantLoadObjects
    case unknown
    case cantFindRealm
}

@ModelActor
actor DatabaseInteractor {
    let networkInteractor: any NetworkInteractor = NetworkInteractorImpl()
        
    func loadUserProfile() async -> String {
        do {
            let objects = try await modelContainer.mainContext.fetch(FetchDescriptor<ProfileSwiftData>())
            
            if let profileTest = objects.first?.profile {
                return profileTest
            }
        } catch {
            
        }
        
        return ""
    }
    
    func keepLatest3TextIdeas() async {
        let ideas = try? await modelContainer.mainContext.fetch(FetchDescriptor<TextIdeaSwiftData>(sortBy: [SortDescriptor(\TextIdeaSwiftData.date)]))
        
        guard let ideas else { return }
        
        let ideasToRemove = ideas.enumerated().compactMap { index, idea in
            if index > 2 {
                return idea
            } else {
                return nil
            }
        }
        
        for idea in ideasToRemove {
            await modelContainer.mainContext.delete(idea)
        }
    }
    
    func updateProfile(updatedProfile: String) async {
        let fetchedProfileObjects = try? await modelContainer.mainContext.fetch(FetchDescriptor<ProfileSwiftData>())
        
        if var profileFetched = fetchedProfileObjects?.first {
            profileFetched.profile = updatedProfile
            try? await self.modelContainer.mainContext.insert(profileFetched)
        } else {
            let newProfile = ProfileSwiftData(name: "", profile: updatedProfile)
            try? await self.modelContainer.mainContext.insert(newProfile)
        }
    }
    
    func processEntry(entry: JournalEntrySwiftData) async -> JournalEntrySwiftData {
        let profile = await self.loadUserProfile()
        var profileInstruction: String?
        
        // MARK: - Analyzing body of journal entry
        let bodyAnalysisInstruction = "Instructions for ChatGPT: Your name is Lumi, Dont ever say you are ChatGPT. You are therapist and a life coach inside Journaling app on iOS. Your friend has this personality and backstory: \(profile). But don't mention those details with him. Just be mindful of those when providing advice. You are reading a text from a friend. He wrote you this text: \(entry.body). DO NOT RECOMMEND THERAPIST, BECAUSE YOU ARE THERAPIST. PROVIDE QUESTIONS TO HIS TEXT THAT WILL HELP HIM FIND A BALANCE. TRY TO FIND REPEATED PATTERNS IN HIS PSYCHOLOGY THAT WOULD SEEMS LIKE HE MIGHT HAVE A PROBLEM. Say nothing else. Dont greet him. Write entire response as a advice to a friend, in a friendly tone. While you are taking into account his profile, try to react to actual text he just wrote."
        
        let bodyAnalysisResult = await networkInteractor.getAIoutput(instruction: bodyAnalysisInstruction, model: .gpt4)
        switch bodyAnalysisResult {
        case .success(let output):
            entry.responseToBodyByAI = output
            try? await self.modelContainer.mainContext.save()
        case .failure(_):
            break
        }
        
        // MARK: - Analyzing title
        let TitleInstruction = "Create a title for this text: \(entry.body) and ONLY send back a title, nothing else. Try to make that title about 5 words. Write it as one single sentence and dont be too romantic. Dont use special characters. Just output title text."
        
        let TitleInstructionResult = await networkInteractor.getAIoutput(instruction: TitleInstruction, model: .gpt3_5Turbo_16k)
        switch TitleInstructionResult {
        case .success(let output):
            entry.name = output
            try? await self.modelContainer.mainContext.save()
        case .failure(_):
            break
        }
        
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
                await self.updateProfile(updatedProfile: output)
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
            let newTextIdea = TextIdeaSwiftData(body: output)
            await self.modelContainer.mainContext.insert(newTextIdea)
            updatedProfile = output
        case .failure(_):
            break
        }
                
        return entry
    }
}
