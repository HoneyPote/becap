//
//  PhotoViewModel.swift
//  becap
//
//  Created by Adam Mabrouki on 05/08/2025.
//
import Firebase

//TODO: A METTRE DANS SERCIVE
class PhotoViewModel: ObservableObject {
  
    @Published var currentPhoto: ChallengePhoto?
    private var photoListener: ListenerRegistration?
    let challengeService = ChallengeService.shared
    @Published var comments: [PhotoCommentModel] = []

    private var commentsListener: ListenerRegistration?

    func listenToComments(challengeId: String, photoId: String) {
        commentsListener?.remove()
        commentsListener = challengeService.listenToComments(challengeId: challengeId, photoId: photoId) { [weak self] newComments in
            DispatchQueue.main.async {
                self?.comments = newComments
            }
        }
    }

    func addComment(_ content: String,
                    challengeId: String,
                    photoId: String,
                    challengeTitle: String) {

        guard let user = UserManager.shared.currentUser else { return }

        // Ajouter le commentaire à Firestore
        challengeService.addComment(to: challengeId, photoId: photoId, content: content, user: user)

        // ⚠️ On veut éviter d’envoyer une notif à soi-même
        guard let photoAuthorUid = currentPhoto?.authorUid,
              photoAuthorUid != user.id else { return }

        // Envoyer la notification OneSignal
        Task {
            await challengeService.sendCommentNotification(
                to: photoAuthorUid,
                from: user.name,
                challengeTitle: challengeTitle,
                commentText: content
            )
        }
    }


      func listenToPhotoRealtime(challengeId: String, photoId: String) {
          photoListener?.remove()
          let ref = Firestore.firestore().collection("challenges").document(challengeId).collection("photos").document(photoId)
          photoListener = ref.addSnapshotListener { [weak self] doc, error in
              guard let self = self else { return }
              guard let updatedPhoto = try? doc?.data(as: ChallengePhoto.self) else { return }
              DispatchQueue.main.async {
                  self.currentPhoto = updatedPhoto
              }
          }
      }

      deinit {
          photoListener?.remove()
          commentsListener?.remove()
      }

    func stopListening() {
        photoListener?.remove()
        commentsListener?.remove()
    }

    func like(photo: ChallengePhoto, userId: String, userName: String, challengeTitle: String) {
        guard let challengeId = photo.challengeId, let photoId = photo.id else { return }
        challengeService.likePhoto(challengeId: challengeId, photoId: photoId, userId: userId) { [weak self] error in
            if let error = error {
                print("❌ Like failed: \(error)")
            } else {
                print("✅ Photo likée !")
                if photo.authorUid != userId {
                    Task {
                        await self?.challengeService.sendLikeNotification(
                            to: photo.authorUid,
                            from: userName,
                            challengeTitle: challengeTitle
                        )
                    }
                }
            }
        }
    }
    func unlike(photo: ChallengePhoto, userId: String) {
        guard let challengeId = photo.challengeId, let photoId = photo.id else { return }
        challengeService.unlikePhoto(challengeId: challengeId, photoId: photoId, userId: userId)
    }

   
}
