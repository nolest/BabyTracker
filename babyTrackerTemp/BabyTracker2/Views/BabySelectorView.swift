import SwiftUI

struct BabySelectorView: View {
    let babies: [Baby]
    @Binding var selectedBaby: Baby?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(babies, id: \.id) { baby in
                    BabyAvatarView(
                        baby: baby,
                        isSelected: baby.id == selectedBaby?.id,
                        action: {
                            selectedBaby = baby
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct BabyAvatarView: View {
    let baby: Baby
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color("PrimaryColor") : Color.clear, lineWidth: 3)
                        )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color("PrimaryColor"))
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color("PrimaryColor") : Color.clear, lineWidth: 3)
                        )
                }
                
                Text(baby.name ?? "Baby")
                    .font(.caption)
                    .foregroundColor(isSelected ? Color("PrimaryColor") : .primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color("PrimaryColor").opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
    }
}
