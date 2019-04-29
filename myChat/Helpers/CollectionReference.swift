//
//  CollectionReference.swift
//  myChat
//
//  Created by Julio Cesar Aguilar Jimenez on 22/03/2019.
//  Copyright © 2019 Julio C. Aguilar. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


// Returns a reference for diferent folders
func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    // Returns full path where we are going to save in firestore
    return Firestore.firestore().collection(collectionReference.rawValue)
}
