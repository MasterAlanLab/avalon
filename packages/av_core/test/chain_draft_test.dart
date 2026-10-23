// The chain form's rules (PRODUCT_SPEC §3.7).
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

const _a = MemberRef.source(configurationId: 'cfg', key: 'a');
const _b = MemberRef.selfNode(id: 'b');

void main() {
  test('build: name optional, at least two distinct hops of hop kinds', () {
    final d = const ChainDraft().add(_a).add(_b);
    expect(d.build(), const Chain(id: '', hops: [_a, _b]));
    expect(d.withName(' 回国 ').build().name, '回国');

    expect(
      const ChainDraft().add(_a).build,
      throwsA(
        isA<ChainDraftException>().having(
          (e) => e.error,
          'error',
          ChainDraftError.tooShort,
        ),
      ),
    );
    expect(
      const ChainDraft(
        hops: [
          _a,
          MemberRef.chain(id: 'x'),
        ],
      ).build,
      throwsA(
        isA<ChainDraftException>()
            .having((e) => e.error, 'error', ChainDraftError.kind)
            .having((e) => e.index, 'index', 1),
      ),
    );
    expect(
      const ChainDraft(hops: [_a, _b, _a]).build,
      throwsA(
        isA<ChainDraftException>()
            .having((e) => e.error, 'error', ChainDraftError.duplicate)
            .having((e) => e.index, 'index', 2),
      ),
    );
  });
}
