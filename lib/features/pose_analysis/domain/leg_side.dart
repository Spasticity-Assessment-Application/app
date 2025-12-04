/// Représente le côté de la jambe à analyser
enum LegSide {
  /// Jambe droite
  right('Jambe droite', 'right'),

  /// Jambe gauche
  left('Jambe gauche', 'left');

  /// Nom d'affichage pour l'UI
  final String displayName;

  final String id;

  const LegSide(this.displayName, this.id);

  /// Récupère un LegSide depuis son id
  static LegSide fromId(String id) {
    return LegSide.values.firstWhere(
      (side) => side.id == id,
      orElse: () => LegSide.right,
    );
  }
}
