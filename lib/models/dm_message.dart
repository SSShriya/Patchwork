class DmMessage {
  final String id;
  final String text;
  final bool fromMe;
  final bool isInvitation;
  final DateTime createdAt;
  final String? lastEditedBy;
  bool? invitationStatus;

  DmMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.createdAt,
    this.isInvitation = false,
    this.invitationStatus,
    this.lastEditedBy,
  });
}
