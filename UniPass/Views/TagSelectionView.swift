//
//  TagSelectionView.swift
//  UniPass
//
//  Created by Kyle Graham on 22/3/2025.
//

import SwiftUI

struct TagSelectionView: View {
    @Binding var selectedTags: [String]
    @Environment(\.dismiss) var dismiss
    
    // Separate tags based on categories
    let tagCategories: [(String, [String])] = [
        ("Tech & Coding", ["Coding", "Programming", "Web Development", "App Development", "AI", "Machine Learning", "Cybersecurity", "Cloud Computing", "Game Development", "Data Science"]),
        ("Music", ["Music", "Rock", "Pop", "Hip Hop", "Jazz", "Classical", "Indie", "EDM", "Singing", "Playing Instruments", "Guitar", "Piano", "Music Production"]),
        ("Sports", ["Sports", "Soccer", "Basketball", "Tennis", "Cricket", "Baseball", "Rugby", "American Football", "Golf", "Swimming", "Cycling", "Martial Arts", "Boxing", "Skateboarding", "Surfing", "Snowboarding", "Esports"]),
        ("Gaming", ["Gaming", "Console Gaming", "PC Gaming", "Mobile Games", "RPG", "MMO", "FPS", "Strategy Games", "Casual Games", "Indie Games", "Streaming"]),
        ("Entertainment", ["Movies", "TV Shows", "Anime", "Cartoons", "Documentaries", "Stand-up Comedy", "Theatre", "YouTube", "Podcasts", "Meme Culture", "Reality TV"]),
        ("Travel & Adventure", ["Travel", "Backpacking", "Road Trips", "Hiking", "Camping", "Beach Days", "Urban Exploration", "Cultural Travel", "Nature", "Mountains", "Solo Travel"]),
        ("Food & Drink", ["Food", "Cooking", "Baking", "Vegan", "Vegetarian", "Street Food", "Fine Dining", "Coffee", "Tea", "Wine", "Craft Beer", "Food Photography"]),
        ("Art & Design", ["Art", "Drawing", "Painting", "Digital Art", "Graphic Design", "3D Modeling", "Animation", "Tattoo Art", "Street Art", "Calligraphy"]),
        ("Photography & Media", ["Photography", "Videography", "Editing", "Vlogging", "Film Making", "Drone Photography", "Nature Photography", "Portraits", "Photo Editing"]),
        ("Fitness & Wellness", ["Fitness", "Gym", "Yoga", "Pilates", "Meditation", "Running", "Bodybuilding", "CrossFit", "Calisthenics", "Nutrition", "Mental Health"]),
        ("Hobbies & Interests", ["Reading", "Writing", "Blogging", "Journaling", "DIY", "Knitting", "Gardening", "Lego", "Board Games", "Puzzle Solving", "Origami", "Language Learning", "Magic Tricks", "Astrology", "Chess"]),
        ("Fashion & Lifestyle", ["Fashion", "Streetwear", "Thrifting", "Makeup", "Skincare", "Interior Design", "Minimalism", "Self Improvement"]),
        ("Misc", ["Animals", "Pets", "Cats", "Dogs", "Volunteering", "Environment", "Tech News", "Space", "History", "Philosophy", "Science"])
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Your Tags")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            ScrollView(showsIndicators: false) {
                ForEach(tagCategories, id: \.0) { category, tags in
                    Text(category)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 10)
                    TagWrapperView(tags: tags, selectedTags: $selectedTags)
                }
            }
            .padding(.bottom, 20)

            Spacer()

            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
