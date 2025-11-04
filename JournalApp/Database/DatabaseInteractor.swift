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
    let networkInteractor: any NetworkInteractor = AppleFMNetworkInteractor.shared
        
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
        do { try modelContext.save() } catch { }
    }
    
    func updateProfile(updatedProfile: String) async {
        let fetchedProfileObjects = try? modelContext.fetch(FetchDescriptor<ProfileSwiftData>())
        if let profileFetched = fetchedProfileObjects?.first {
            profileFetched.profile = updatedProfile
        } else {
            let newProfile = ProfileSwiftData(name: "", profile: updatedProfile)
            modelContext.insert(newProfile)
        }
        do {
            try modelContext.save()
        } catch {
            // Handle or log the save error if desired
        }
    }
    
    func processEntry(entry: JournalEntrySwiftData) async throws -> JournalEntrySwiftData {
        // Load existing profile and unwrap body safely to avoid Optional(...) in prompts
        let profile = await self.loadUserProfile()
        let body = entry.body ?? ""

        // MARK: - Analyze entry and produce a tweaked instruction for the user
        let analysisInstruction = """
        You are Lumi, a warm, friendly therapist and life coach inside an iOS journaling app. Read the user's journal entry in the context of their profile and produce:
        1) A short, empathetic reflection (2–3 sentences) that shows you understood the entry.
        2) ONE clear, tailored next-step instruction the user can do today to help them reflect or make progress. This should be concrete and actionable (start with a verb). Keep it to one sentence.
        Output format:
        Reflection: <your reflection>
        Instruction: <your single instruction>

        Profile:
        \(profile)

        Entry:
        \(body)
        """

        async let analysisResult = await networkInteractor.getAIoutput(instruction: analysisInstruction, modelIdentifier: "foundation-transformer")
        switch await analysisResult {
        case .success(let output):
            // Store the combined reflection + instruction so UI can show both
            entry.responseToBodyByAI = output
            do { try modelContext.save() } catch { throw error }
        case .failure(let error):
            throw error
        }

        // MARK: - Generate concise title from body
        let titleInstruction = """
        Create a concise title (about 5 words) for the following text. Output only the title, no quotes or extra text, no special characters.

        Text:
        \(body)
        """

        async let titleResult = await networkInteractor.getAIoutput(instruction: titleInstruction, modelIdentifier: "foundation-transformer")
        switch await titleResult {
        case .success(let output):
            entry.name = output
            do { try modelContext.save() } catch { throw error }
        case .failure(let error):
            throw error
        }

        // MARK: - Update profile based on this entry
        let profileInstruction: String
        if profile.isEmpty {
            profileInstruction = """
            You are Lumi, a therapist in an iOS journaling app. Based on the user's entry below, write an initial, concise profile of the user that focuses on their personality, challenges, strengths, and areas to focus on next. Do not mention name or age. Write it as if speaking kindly to the user.

            Entry:
            \(body)
            """
        } else {
            profileInstruction = """
            You are Lumi, a therapist in an iOS journaling app. Update the user's existing profile below by integrating new insights from the latest entry. Keep it concise and kind, focusing on personality, challenges, strengths, and next focus areas. Do not mention name or age. Write it as if speaking to the user.

            Current Profile:
            \(profile)

            New Entry:
            \(body)
            """
        }

        async let updatedProfileResult = await networkInteractor.getAIoutput(instruction: profileInstruction, modelIdentifier: "foundation-transformer")
        switch await updatedProfileResult {
        case .success(let output):
            await self.updateProfile(updatedProfile: output)
        case .failure(let error):
            throw error
        }

        // MARK: - Generate a new short prompt idea based on updated profile context
        let newTextIdeaInstruction = """
        Based on the user's profile below, generate ONE short, friendly prompt for the next journal entry that helps the user reflect and make progress. Output only the prompt text.

        Profile:
        \(await self.loadUserProfile())
        """

        async let newTextIdeaResult = await networkInteractor.getAIoutput(instruction: newTextIdeaInstruction, modelIdentifier: "foundation-transformer")
        switch await newTextIdeaResult {
        case .success(let output):
            let newTextIdea = TextIdeaSwiftData(body: output)
            modelContext.insert(newTextIdea)
            do { try modelContext.save() } catch { throw error }
        case .failure(let error):
            throw error
        }

        return entry
    }
}

