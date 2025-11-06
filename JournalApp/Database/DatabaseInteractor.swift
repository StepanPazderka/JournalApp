//
//  DatabaseInteractor.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 01.12.2023.
//

import Foundation
import SwiftData

@ModelActor
actor DatabaseInteractor: ObservableObject {
	let aiAnalyzer: any NetworkInteractor = AppleFMNetworkInteractor.shared
	
	/// Fetches a SwiftData object by its Persistent Identifier, applies a mutation, and saves.
	/// - Parameters:
	///   - type: The model type to fetch.
	///   - id: The `persistentModelID` of the object.
	///   - mutate: Closure that mutates the managed instance in place.
	/// - Returns: The mutated instance for optional chaining.
	private func update<T: PersistentModel>(_ instance: T) {
		let pid = instance.persistentModelID
		let descriptor = FetchDescriptor<T>(
			predicate: #Predicate { $0.persistentModelID == pid }
		)
		if let managed = try? modelContext.fetch(descriptor).first, managed.persistentModelID == instance.persistentModelID {
			modelContext.insert(instance)
		} else {
			modelContext.insert(instance)
		}
		try? modelContext.save()
	}
	
	func loadUserProfile() async -> String {
		(try? modelContext.fetch(FetchDescriptor<ProfileSwiftData>()))?.first?.profile ?? ""
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
		
		// Ensure the passed entry is managed by this actor's context
		let pid = entry.persistentModelID
		let entryDescriptor = FetchDescriptor<JournalEntrySwiftData>(
			predicate: #Predicate { $0.persistentModelID == pid }
		)
		// If not found in this context, insert it so mutations are tracked
		if (try? modelContext.fetch(entryDescriptor).first) == nil {
			modelContext.insert(entry)
			do { try modelContext.save() } catch { throw error }
		}
		
		// MARK: - Analyze entry and produce a tweaked instruction for the user
		let analysisInstruction = AIPrompts.analysis(profile: profile, body: body)
		
		async let analysisResult = await aiAnalyzer.getAIoutput(instruction: analysisInstruction)
		switch await analysisResult {
		case .success(let output):
			// Store the combined reflection + instruction so UI can show both
			entry.responseToBodyByAI = output
			
			let pid = entry.persistentModelID
			let descriptor = FetchDescriptor<JournalEntrySwiftData>(
				predicate: #Predicate { $0.persistentModelID == pid }
			)
			if let managedEntry = try modelContext.fetch(descriptor).first {
				managedEntry.responseToBodyByAI = output
			}
			
			do {
				try modelContext.save()
			} catch {
				throw error
			}
		case .failure(let error):
			throw error
		}
		
		// MARK: - Generate concise title from body
		let titleInstruction = AIPrompts.title(from: body)
		
		async let titleResult = await aiAnalyzer.getAIoutput(instruction: titleInstruction)
		
		switch await titleResult {
		case .success(let output):
			entry.name = output
			update(entry)
		case .failure(let error):
			if let managed = try? modelContext.fetch(FetchDescriptor<JournalEntrySwiftData>(predicate: #Predicate { $0.persistentModelID == pid })).first {
				managed.name = entry.body
				try modelContext.save()
			} else {
				entry.name = entry.body
				update(entry)
			}
			throw error
		}
		
		// MARK: - Update profile based on this entry
		let profileInstruction: String = profile.isEmpty
		? AIPrompts.initialProfile(from: body)
		: AIPrompts.updateProfile(current: profile, newEntry: body)
		
		async let updatedProfileResult = await aiAnalyzer.getAIoutput(instruction: profileInstruction)
		switch await updatedProfileResult {
		case .success(let output):
			await self.updateProfile(updatedProfile: output)
		case .failure(let error):
			throw error
		}
		
		// MARK: - Generate a new short prompt idea based on updated profile context
		let newTextIdeaInstruction = AIPrompts.nextTextIdea(profile: await self.loadUserProfile())
		
		async let newTextIdeaResult = await aiAnalyzer.getAIoutput(instruction: newTextIdeaInstruction)
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

