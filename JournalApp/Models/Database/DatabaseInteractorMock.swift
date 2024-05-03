//
//  DatabaseInteractorMock.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 04.03.2024.
//

import Foundation
import SwiftData

@ModelActor
actor DatabaseInteractorMock {
	@MainActor static func mockContainer() -> ModelContainer {
        let schema = Schema([JournalEntrySwiftData.self, TextIdeaSwiftData.self, ProfileSwiftData.self])
		var container = try! ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
        
		let profile = ProfileSwiftData(name: "Smith", profile: "In therapy, John Smith, a 30-year-old graphic designer, is addressing his chronic anxiety and occasional depression. He sought support upon realizing the impact of these issues on his work performance and social interactions. Despite a supportive family background, John struggles with a sense of inadequacy, largely fueled by his perfectionism and an intensified fear of failure following his divorce two years ago. Therapy sessions are centered on challenging his negative thought patterns and fostering adaptive coping strategies. Initially hesitant about engaging in therapy, John has been developing a keen interest in mindfulness practices and is gradually opening up about his past experiences, indicating positive progress in his journey towards improved mental health.")
		container.mainContext.insert(profile)
		
		let journalEntryMock1 = JournalEntrySwiftData(date: Date(), name: "Reflections on a Rainy Day", body: "Today, as the rain gently pattered against my window, I found myself lost in a sea of thoughts, mostly about my recent interactions - or lack thereof - with Emily. I've seen her in the library often, her nose always buried in books about far-off places and cultures. I admire that about her, the way she seems so engrossed in her own world. It's like she's part of a story that I long to be a part of.\n\nBut as an INFP, I find it hard to break through that invisible barrier that seems to separate me from others. My mind crafts narratives of beautiful conversations and shared interests, but reality is a stark contrast - silent nods and quick smiles. I wonder what it would be like to just walk up to her and start a conversation, but the thought alone sends a wave of anxiety through me.\n\nMaybe tomorrow, I'll be a little braver. Maybe I'll finally say more than just a timid 'hello'. Or perhaps, I'll find solace once again in these pages, where words flow far easier than they do in the corridors of life.")
		container.mainContext.insert(journalEntryMock1)
		
		let journalEntryMock2 = JournalEntrySwiftData(date: Date(), name: "A Day of Reflection", body: "Work today was particularly challenging. I faced a tough situation with a project deadline looming and a team member falling ill unexpectedly. It was a test of my problem-solving skills and patience. I had to reorganize the team's tasks, delegate different responsibilities, and spend extra hours at the office. But, in the end, we managed to meet the deadline. This experience taught me a lot about leadership and resilience. It's in moments like these that I truly understand the importance of teamwork and clear communication.")
		container.mainContext.insert(journalEntryMock2)
		
		let journalEntryMock3 = JournalEntrySwiftData(date: Date(), name: "An Unexpected Adventure", body: "Today turned out to be an unexpected adventure! I had planned a routine day, but a surprise call from an old friend changed everything. We decided on an impromptu road trip to a nearby town we used to visit during our college days. The nostalgia was palpable as we walked through the familiar streets, reminiscing about old times and catching up on new stories. It's incredible how some friendships just pick up right where they left off, no matter how much time has passed. Today reminded me of the value of spontaneous decisions and the enduring nature of true friendship.")
		container.mainContext.insert(journalEntryMock3)
				
		for i in 1...11 {
			let idea = TextIdeaSwiftData(body: "Idea body \(i)")
			container.mainContext.insert(idea)
		}
		
		return container
    }
}
