import 'package:flutter_test/flutter_test.dart';
import 'package:shjsdsc/core/models/athlete_extras.dart';
import 'package:shjsdsc/core/repository/demo_repository.dart';

void main() {
  test('document derived status reflects expiry windows', () async {
    final repo = DemoRepository();
    final rashid = (await repo.athlete('ath-1'))!;
    expect(rashid.documents.length, 3);

    final licence = rashid.documents
        .firstWhere((d) => d.kind == AthleteDocumentKind.federationLicence);
    expect(licence.derivedStatus(), AthleteDocumentStatus.expiringSoon);

    final emiratesId = rashid.documents
        .firstWhere((d) => d.kind == AthleteDocumentKind.emiratesID);
    expect(emiratesId.derivedStatus(), AthleteDocumentStatus.valid);

    final hamad = (await repo.athlete('ath-3'))!;
    final wtCard = hamad.documents
        .firstWhere((d) => d.kind == AthleteDocumentKind.worldTaekwondoCard);
    expect(wtCard.derivedStatus(), AthleteDocumentStatus.expired);
  });
}
