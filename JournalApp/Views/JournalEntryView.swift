//
//  ContentView.swift
//  JournalApp
//
//  Created by Štěpán Pazderka on 30.11.2023.
//

import SwiftUI
import OpenAI
import Combine
import SwiftData

struct JournalEntryView: View {
	@Query(sort: \JournalEntrySwiftData.date) var entriesSwiftData: [JournalEntrySwiftData]
	@Query(sort: \TextIdeaSwiftData.date) var ideasSwiftData: [TextIdeaSwiftData]
	
	let icloudDefaults = NSUbiquitousKeyValueStore.default
	
	var entry: JournalEntrySwiftData?
	@StateObject var viewModel = JournalEntryViewModelImpl()
	
	@State var journalBody = ""
	@State var journalResponse = ""
	
	@State private var showNotificationOverBody = false
	@State private var showNotificationOverResponse = false
	
	@FocusState private var isTextEditorInFocus: Bool
	
	@State private var progress = 0.0
	@State private var textEditorDisabled = false
	
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.modelContext) private var context
	
	@State private var cancellables = Set<AnyCancellable>()
	
	@State private var showingRenameDialog = false
	@State private var nameForRenaming = ""
	
	init(entry: JournalEntrySwiftData? = nil) {
		self.journalBody = entry?.body ?? ""
		self.journalResponse = entry?.responseToBodyByAI ?? ""
		self.entry = entry
	}
	
	var body: some View {
		GeometryReader { geometry in
			ScrollView {
				VStack {
					// MARK: TextEditor
					ZStack {
						if entry == nil || journalBody.isEmpty {
							if let idea = ideasSwiftData.randomElement() {
								if journalBody.isEmpty {
									Text(idea.body.replacingOccurrences(of: "\"", with: ""))
										.padding(9)
										.opacity((entry == nil && journalBody.isEmpty) ? 0.2 : 0.0)
										.multilineTextAlignment(.leading)
										.disabled(entry != nil)
								}
							} else {
								Text(journalBody.isEmpty || entry != nil ? "Enter text here" : "")
									.opacity((entry == nil && journalBody.isEmpty) ? 0.2 : 0.0)
									.multilineTextAlignment(.leading)
									.disabled(!journalBody.isEmpty)
							}
						}
						if let entry {
							ZStack {
								Text(entry.body ?? "")
									.padding(9)
									.contextMenu {
										Button {
#if os(macOS)
											NSPasteboard.general.writeObjects([entry.body! as NSString])
#else
											UIPasteboard.general.string = entry.body
#endif
											withAnimation {
												showNotificationOverBody = true
												DispatchQueue.main.asyncAfter(deadline: .now()+2) {
													withAnimation {
														showNotificationOverBody = false
													}
												}
											}
										} label: {
											Label("Copy to clipboard", systemImage: "doc.on.doc")
										}
									}
									.frame(maxWidth: .infinity)
								if showNotificationOverBody {
									Text("Copied into clipboard")
										.padding()
										.background(Color.blue)
										.foregroundColor(.white)
										.cornerRadius(10)
										.opacity(showNotificationOverBody ? 1 : 0)
										.transition(.opacity)
								}
							}
						} else {
							TextEditor(text: $journalBody)
								.frame(minHeight: 40)
								.padding(9)
								.scrollContentBackground(.hidden)
								.background(colorScheme == .light ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
								.clipShape(RoundedRectangle(cornerRadius: 25.0))
								.focused($isTextEditorInFocus)
								.onAppear {
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
										isTextEditorInFocus = true
									}
								}
								.disabled(textEditorDisabled)
						}
						
						Text(journalBody)
							.opacity(0)
							.padding(.all, 8)
					}
					
					// MARK: Response
					ZStack {
						Text(entry?.responseToBodyByAI ?? journalResponse)
							.padding()
							.background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.1), Color.blue.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
							.cornerRadius(25)
							.disabled(journalResponse.isEmpty)
							.contextMenu {
								Button {
#if os(macOS)
									NSPasteboard.general.writeObjects([entry!.responseToBodyByAI! as NSString])
#else
									UIPasteboard.general.string = entry?.responseToBodyByAI
#endif
									withAnimation {
										showNotificationOverResponse = true
										DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
											withAnimation {
												showNotificationOverResponse = false
											}
										})
									}
								} label: {
									Label("Copy to clipboard", systemImage: "doc.on.doc")
								}
							}
							.opacity(journalResponse.isEmpty ? 0 : 1)
							.transition(.opacity)
							.animation(!journalResponse.isEmpty ? nil : .easeIn(duration: 0.3), value: self.journalResponse)
							.lineLimit(nil)
						if showNotificationOverResponse {
							Text("Copied into clipboard")
								.padding()
								.background(Color.blue)
								.foregroundColor(.white)
								.cornerRadius(10)
								.opacity(showNotificationOverResponse ? 1 : 0)
								.transition(.opacity)
						}
						ProgressView(value: progress)
							.progressViewStyle(.circular)
							.hidden(!journalResponse.isEmpty || progress == 0)
						
						Spacer()
						
						// MARK: Save button
						if journalResponse.isEmpty {
							Button("Save") {
								self.saveJournalEntry()
							}
							.frame(height: 50)
							.hidden(!journalResponse.isEmpty || progress > 0)
						}
					}
				}
				.padding(20)
				.onAppear {
					viewModel.setup(context: self.context)
					
					if let filteredEntry = self.entriesSwiftData.first(where: { $0.date == entry?.date }) {
						self.journalResponse = filteredEntry.responseToBodyByAI ?? ""
					}
					
					if let savedTextFromCloud = icloudDefaults.object(forKey: "draft") as? String {
						self.journalBody = savedTextFromCloud
					}
					
					if let response = entry?.responseToBodyByAI, response.isEmpty {
						DispatchQueue.global().asyncAfter(deadline: .now()+0.1) {
							self.journalBody.append(" ")
							usleep(100)
							self.journalBody.removeLast()
						}
					}
					
					viewModel.$showingAlert.sink { value in
						self.progress = 0.0
					}.store(in: &cancellables)
				}
				.alert(viewModel.alertMessage, isPresented: $viewModel.showingAlert) {
					Button("OK", role: .cancel) { }
				}
				.onChange(of: journalBody) { oldValue, newValue in
					if journalResponse.isEmpty {
						icloudDefaults.set(newValue, forKey: "draft")
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .principal) {
					Button {
						showingRenameDialog.toggle()
						nameForRenaming = entry?.name ?? ""
					} label: {
						VStack {
							if let title = entry?.name {
								Text(title).font(.headline)
							}
							if let date = entry?.date {
								Text(format(Date: date))
									.font(.system(size: 10))
									.opacity(0.5)
							}
						}
					}
					.foregroundStyle(.foreground)
				}
			}
			.alert("Rename entry", isPresented: $showingRenameDialog) {
				TextField("Enter entry name", text: $nameForRenaming)
				Button("OK", role: .cancel) {
					if let entry {
						entry.name = nameForRenaming
						context.insert(entry)
					}
				}
			}
		}
	}
	
	func saveJournalEntry() {
		textEditorDisabled = true
		progress = 0.1
		Task {
			if let alreadyWrittenEntry = entry {
				let result = await viewModel.process(entry: alreadyWrittenEntry)
				self.journalResponse = result.responseToBodyByAI ?? ""
			} else {
				let newEntrySwiftData = JournalEntrySwiftData(date: Date(), name: "", body: journalBody)
				context.insert(newEntrySwiftData)
				try? context.save()
				print(newEntrySwiftData)
				
				let result = await viewModel.process(entry: newEntrySwiftData)
				self.journalResponse = result.responseToBodyByAI ?? ""
				icloudDefaults.removeObject(forKey: "draft")
				print("ID of new swift data journal entry: \(newEntrySwiftData.id)")
			}
		}
		progress = 1.0
	}
}
//
//#Preview {
//    let previewEntry = JournalEntry(id: UUID(), name: "Name", date: Date(), body: "Today was tougher than usual. I felt overwhelmed by the smallest tasks at work and at home. It's like a heavy cloud is hanging over me, making it hard to see the good in my day. I noticed I'm more irritable lately, snapping at my partner over trivial things. I'm also struggling to sleep well, which just adds to the feeling of being drained. I know I should be more positive, but it's just so hard right now.", responseToBodyByAI: "Thank you for sharing your feelings so openly in your journal. It's clear you're going through a challenging time. Feeling overwhelmed and experiencing changes in mood and sleep are significant, and it's important to acknowledge these feelings rather than dismissing them. \n\nFirstly, it's okay not to feel positive all the time. Emotions, even the difficult ones, are part of our human experience and provide us with valuable information about our needs. Your irritability and fatigue suggest that you might be needing more self-care or rest. \n\n I encourage you to explore some small, manageable steps that can help you cope with these feelings. This might include setting aside some time for relaxation, engaging in activities you enjoy, or practicing mindfulness to stay grounded in the present moment.\n\nRemember, it's not about removing the cloud but learning how to walk in the rain with an umbrella. We'll continue to work together to find strategies that help you manage these feelings and improve your overall well-being.")
//    JournalEntryView(entry: JournalEntrySwiftData(from: previewEntry))
//}

//#Preview {
//    JournalEntryView()
//}
