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
	case unknown(description: String)
}

@ModelActor
actor DatabaseInteractor: ObservableObject {
    let networkInteractor: any NetworkInteractor = NetworkInteractorImpl()
        
    func loadUserProfile() async -> String {
        do {
            let objects = try modelContext.fetch(FetchDescriptor<ProfileSwiftData>())
            
            if let profileTest = objects.first?.profile {
                return profileTest
            }
        } catch {
            
        }
        
        return ""
    }
	
	func loadUserProfileReturnTask() -> Result<ProfileSwiftData, DatabaseInteractorError> {
		guard let profileObject = try? modelContext.fetch(FetchDescriptor<ProfileSwiftData>()).first else { return .failure(.cantLoadObjects) }
		return .success(profileObject)
	}
    
    func keepLatest3TextIdeas() async {
        let ideas = try? modelContext.fetch(FetchDescriptor<TextIdeaSwiftData>(sortBy: [SortDescriptor(\TextIdeaSwiftData.date)]))
        
        guard let ideas else { return }
        
        let ideasToRemove = ideas.enumerated().compactMap { index, idea in
			index > 2 ? idea : nil
        }
        
        for idea in ideasToRemove {
			modelContext.delete(idea)
        }
    }
    
    func updateProfile(updatedProfile: String) async {
        let fetchedProfileObjects = try? modelContext.fetch(FetchDescriptor<ProfileSwiftData>())
        
        if let profileFetched = fetchedProfileObjects?.first {
            profileFetched.profile = updatedProfile
            modelContext.insert(profileFetched)
        } else {
            let newProfile = ProfileSwiftData(name: "", profile: updatedProfile)
            modelContext.insert(newProfile)
        }
    }
    
    func processEntry(entry: JournalEntrySwiftData) async throws -> JournalEntrySwiftData {
        let profile = await self.loadUserProfile()
        var profileInstruction: String?
        
        // MARK: - Analyzing body of journal entry
        let bodyAnalysisInstruction = "Instructions for ChatGPT: Your name is Lumi, Dont ever say you are ChatGPT. You are therapist and a life coach inside Journaling app on iOS. Your friend has this personality and backstory: \(profile). But don't mention those details with him. Just be mindful of those when providing advice. You are reading a text from a friend. He wrote you this text: \(String(describing: entry.body)). DO NOT RECOMMEND THERAPIST, BECAUSE YOU ARE THERAPIST. PROVIDE ONE AND ONLY ONE INSIGHTFUL QUESTIONS THAT WOULD HELP HIM SEE THINGS FROM DIFFERENT PERSPECTIVE, HE DIDNT CONSIDERED BEFORE. Say nothing else. Dont greet him. Write entire response as a advice to a friend, in a friendly tone. While you are taking into account his profile, try to react to actual text he just wrote. Try to be useful, helpful, insightful, offer new perspectives, maybe joke (not necessarily) but try to write two paragraphs."
        
        let bodyAnlysisInstruction_second = "Analyze the user's text journal entry: \(entry.body) in conjunction with their profile: \(profile), which summarizes key personal attributes, preferences, life circumstances, and any specific challenges or goals they have shared. Identify the primary themes, emotions, and specific situations described in the journal entry. Craft empathetic, constructive, and highly personalized advice that not only addresses the content of the entry but also aligns with the broader context of the user's life as outlined in their profile. Offer strategies for coping, personal growth, and problem-solving that are tailored to the user's unique journey, emphasizing progress, self-care, and the value of professional support when needed. Celebrate any achievements or positive developments noted, and encourage continued reflection and proactive steps towards their goals. Write entire output friendly, as a advice to a friend, if you know users name, use it, otherwise just try to be friendly."
        
        async let bodyAnalysisResult = await networkInteractor.getAIoutput(instruction: bodyAnlysisInstruction_second, model: .gpt4)
        switch await bodyAnalysisResult {
        case .success(let output):
            entry.responseToBodyByAI = output
			if modelContext.hasChanges {
				try? modelContext.save()
			}
        case .failure(let error):
			throw error
        }
        
        // MARK: - Analyzing title
		let TitleInstruction = "Create a title for this text: \(String(describing: entry.body)) and ONLY send back a title, nothing else. Try to make that title about 5 words. Write it as one single sentence and dont be too romantic. Dont use special characters. Just output title text."
        
        async let TitleInstructionResult = await networkInteractor.getAIoutput(instruction: TitleInstruction, model: .gpt3_5Turbo_16k)
        switch await TitleInstructionResult {
        case .success(let output):
            entry.name = output
			if modelContext.hasChanges {
				try? modelContext.save()
			}
        case .failure(let error):
			throw error
        }
        
        // MARK: - Analyzing profile
        if let body = entry.body {
            if profile.isEmpty {
                profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user written text \(body) and respond back only a profile about what you learned about a person who wrote thise, try to understand issues and problems, pick out characeteristics of long term well being of patient, try to understand personality of user and what to focus on next in order to help him or her live a better life. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
            } else {
                profileInstruction = "Your name is Lumi, you are a therapist Journal app running on iOS. Take this user profile: \(profile) and take this user written text \(body) and respond back only new updated profile where you combine these two, pick out characeteristics of long term well being of patient, try to understand issues and problems, try to understand personality of user and what to focus on next. Dont ever talk about his name or age. Write it like you writing this to the patient, treat him like a friend"
            }
        }
        
        if let profileInstruction {
            async let result = await networkInteractor.getAIoutput(instruction: profileInstruction, model: .gpt3_5Turbo_16k)
            switch await result {
            case .success(let output):
                await self.updateProfile(updatedProfile: output)
            case .failure(let error):
                throw error
            }
        }
        
        // MARK: - Generating new idea
        let newTextIdeaInstruction = "Based on new updated profile about your patient, generate a new short text prompt for new journal entry that will help him and you understand user better. Try to by nice and friendly, try to suggest something that would help him to live a better life or help you understand him better. Instructions that needs to be obeyed by ChatGPT: By short! Only respond with text prompt itself, no other text! Be friendly! Try to be motivational and optimistic!"
        
        async let newTextIdeaResult = await networkInteractor.getAIoutput(instruction: newTextIdeaInstruction, model: .gpt3_5Turbo_16k)
        switch await newTextIdeaResult {
        case .success(let output):
            let newTextIdea = TextIdeaSwiftData(body: output)
			modelContext.insert(newTextIdea)
        case .failure(let error):
            throw error
        }
                
        return entry
    }
}

