//
//  TestView.swift
//  TriviaGame
//
//  Created by kuet on 23/11/23.
//

import SwiftUI
import Firebase

struct TestView: View {
    
    private var databaseRef = Database.database().reference()
    @State var options = [[String: Any]]()
    @State var question = [String]()
    

    func fetchData() {
        databaseRef.child("quizes").child("20231122120721").child("question")
            .observeSingleEvent(of: .value) { (snapshot,err) in
                    guard let data = snapshot.value as? [String: [String: Bool]] else {
                        print("Error: Unable to parse data from Firebase")
                        return
                    }

                options = data.compactMap { key, value in
                        return value
                    }
                
                var i = 0
                
                    for key in data.keys{
                        //print(key)
                        question.append(key)
                        print(question[i])
                        i=i+1
                    }

                    // Print the retrieved questions to the console
                    for (index, opt) in self.options.enumerated() {
                        print("Question \(index + 1):")
                        for (key, value) in opt {
                            print("  - \(key): \(value)")
                        }
                        print("\n")
                    }
                }
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear{
                fetchData()
            }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
