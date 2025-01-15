import SwiftUI
import Firebase
import FirebaseFirestore

struct ShowQuiz: View {
    
    @State var questionTxt=""
    
    private var db = Firestore.firestore()  // Firestore reference
    @State var options = [[String: Any]]()
    @State var question = [String]()
    @State var ansOption = [String]()
    @State var ans = [Bool]()
    @State var selected = [false,false,false,false]
    public var quizid:String
    @State var index:Int = 0
    
    @State private var isSelected = false
    @State private var iscorrect = false
    @State private var isComplete = false
    
    @State  var op1 = false
    @State  var op2 = false
    @State  var op3 = false
    @State  var op4 = false
    @State var result = 0
    
    // Custom colors
    var green = Color(hue: 0.437, saturation: 0.711, brightness: 0.711)
    var red = Color(red: 0.71, green: 0.094, blue: 0.1)
    
    init(id:String){
        quizid = id
    }

    var body: some View {
        ZStack{
            VStack(spacing: 40) {
                Spacer().frame(height: 50)
                
                HStack {
                    Text("Trivia Game")
                        .lilacTitle()
                    
                    Spacer()
                    
                    Text("\(index + 1) out of \(question.count)")
                        .foregroundColor(Color("AccentColor"))
                        .fontWeight(.heavy)
                }
                
                // Ensure that progress is 0 if question.count is 0
                ProgressBar(progress: question.count > 0 ? CGFloat(Double((index + 1)) / Double(question.count) * 350) : 0)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(question.count > index ? question[index] : "-")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundColor(.gray)
                    
                    OptionView(index: 0, ansOption: ansOption, ans: ans, selected: $selected, result: $result)
                    OptionView(index: 1, ansOption: ansOption, ans: ans, selected: $selected, result: $result)
                    OptionView(index: 2, ansOption: ansOption, ans: ans, selected: $selected, result: $result)
                    OptionView(index: 3, ansOption: ansOption, ans: ans, selected: $selected, result: $result)
                }
                
                Button {
                    index += 1
                    isSelected = false
                    selected = [false, false, false, false]
                    
                    if index == question.count {
                        isComplete = true
                    } else {
                        accessData()
                    }
                } label: {
                    PrimaryButton(text: "Next", background: isSelected ? Color("AccentColor") : Color(hue: 1.0, saturation: 0.0, brightness: 0.564, opacity: 0.327))
                }
                .disabled(!isSelected)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.984313725490196, green: 0.9294117647058824, blue: 0.8470588235294118))
            .navigationBarHidden(true)
            .onAppear {
                fetchData()
            }
            
            if isComplete {
                ResultView(score: result, totalQues: question.count, quizId: quizid)
            }
        }
    }

    func fetchData() {
        db.collection("quizes").document(quizid).collection("questions")
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    print("Error: Unable to fetch data from Firestore")
                    return
                }

                // Clear current data before adding new ones
                question.removeAll()
                options.removeAll()

                for document in snapshot.documents {
                    let data = document.data()
                    question.append(document.documentID) // Adding question title
                    options.append(data)  // Saving the options for each question
                }

                // After data is fetched, call accessData
                if !options.isEmpty {
                    accessData()
                }
        }
    }

    func accessData() {
        ansOption.removeAll()
        ans.removeAll()

        // Ensure that the index is within the bounds of the options array
        if index < options.count {
            let currentOptions = options[index]
            for (key, value) in currentOptions {
                ansOption.append(key)  // Option text
                if let isCorrect = value as? Bool {
                    ans.append(isCorrect)  // True/False for correct answer
                }
            }
        }
    }
}

struct OptionView: View {
    var index: Int
    var ansOption: [String]
    var ans: [Bool]
    @Binding var selected: [Bool]
    @Binding var result: Int
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "circle.fill")
                .font(.caption)
            
            Text(ansOption.count > index ? ansOption[index] : "-")
                .bold()
            
            if selected[index] {
                Spacer()
                
                Image(systemName: ans[index] ? "checkmark.circle.fill" : "x.circle.fill")
                    .foregroundColor(ans[index] ? Color.green : Color.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundColor(selected[index] ? Color("AccentColor") : Color("AccentColor"))
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: selected[index] ? (ans[index] ? Color.green : Color.red) : .gray, radius: 5, x: 0.5, y: 0.5)
        .onTapGesture {
            if !selected.contains(true) {
                selected[index] = true
                if ans[index] {
                    result += 1
                }
            }
        }
    }
}

struct ShowQuiz_Previews: PreviewProvider {
    static var previews: some View {
        ShowQuiz(id: "---")
    }
}
