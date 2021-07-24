//
//  ContentView.swift
//  iOSPlay
//
//  Created by Ronald on 24/7/21.
//

import SwiftUI
import UIKit
import Alamofire

struct ContentView: View {
    @State var name: String = ""    
    @State private var showingImagePicker = false
    
    @State private var image: Image?
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Name", text: $name)
                        .padding()
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(9)
                        .font(.system(size: 30, weight: .bold, design: .default))
                    
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.secondary)

                        // display the image
                        if image != nil {
                            image?
                                .resizable()
                                .scaledToFit()
                        } else {
                            Text("Tap to select a picture")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .onTapGesture {
                        // select an image
                        self.showingImagePicker.toggle()
                    }
                    
                    
                    Button(action: {
                        uploadToServer(image: self.inputImage)
                    }) {
                        Text("Submit")
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .cornerRadius(9)
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                    }
                    
                }
                .padding(.horizontal)
                .padding(.vertical, 30)
                Spacer()
            }
            .navigationBarTitle("New Form", displayMode: .inline)
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage, sourceType: .photoLibrary)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func uploadToServer(image: UIImage?) {
        
        let headers: HTTPHeaders = [
                /* "Authorization": "your_access_token",  in case you need authorization header */
                "Content-type": "multipart/form-data"
            ]
        
        if image != nil && self.name != "" {
            AF.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(name.data(using: .utf8)!, withName: "username")
                multipartFormData.append(image!.jpegData(compressionQuality: 0.5)!, withName: "avatar", fileName: "file.jpeg", mimeType: "image/jpeg")
            }, to: "http://localhost:3000/profile", method: .post, headers: headers).responseDecodable(of: UploadResponse.self) { (resp) in
                if let payload = resp.value {
                    print("status: \(payload.status)")
                }
            }
        }else{
            print("Image is empty")
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
    
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
      var fieldString = "--\(boundary)\r\n"
      fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
      fieldString += "\r\n"
      fieldString += "\(value)\r\n"

      return fieldString
    }

    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
      let data = NSMutableData()

      data.appendString("--\(boundary)\r\n")
      data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
      data.appendString("Content-Type: \(mimeType)\r\n\r\n")
      data.append(fileData)
      data.appendString("\r\n")

      return data as Data
    }
}

class UploadResponse : Decodable {
    var status: String
    var location: String
}


extension NSMutableData {
  func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct ImagePicker : UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                    parent.image = uiImage
                }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
