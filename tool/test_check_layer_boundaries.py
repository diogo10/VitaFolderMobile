"""Fixture tests for tool/check_layer_boundaries.py (ADR-0006, R1-R5).

Run: python3 -m unittest tool.test_check_layer_boundaries -v
(or: python3 tool/test_check_layer_boundaries.py)
"""

import unittest

try:
    from check_layer_boundaries import check_text
except ImportError:  # `python -m unittest tool.test_...` from repo root.
    from tool.check_layer_boundaries import check_text


def has_rule(hits: list[str], rule: str) -> bool:
    return any(h.startswith(rule + ' ') for h in hits)


class CheckLayerBoundariesTest(unittest.TestCase):
    def test_positive_clean_files_hold(self) -> None:
        domain = (
            "import 'package:meta/meta.dart';\n"
            "import 'package:house_mira/features/people/domain/entities/person_entity.dart';\n"
            '@immutable\n'
            'class A { const A(); }\n'
        )
        self.assertEqual(
            check_text(
                'lib/features/home/domain/entities/a.dart',
                'home',
                'domain',
                domain,
            ),
            [],
        )
        data = "import 'package:supabase_flutter/supabase_flutter.dart';\n"
        self.assertEqual(
            check_text(
                'lib/features/notes/data/repository/r.dart',
                'notes',
                'data',
                data,
            ),
            [],
        )
        presentation = (
            "import 'package:flutter/material.dart';\n"
            "import 'package:flutter_bloc/flutter_bloc.dart';\n"
        )
        self.assertEqual(
            check_text(
                'lib/features/notes/presentation/views/v.dart',
                'notes',
                'presentation',
                presentation,
            ),
            [],
        )

    def test_r1_flutter_import_in_domain_single_rule(self) -> None:
        for line in (
            "import 'package:flutter/material.dart';",
            'import "package:flutter/widgets.dart";',
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'dart:ui';",
            "import 'dart:ui' show Color;",
        ):
            with self.subTest(line=line):
                hits = check_text(
                    'lib/features/home/domain/entities/a.dart',
                    'home',
                    'domain',
                    line + '\n',
                )
                self.assertTrue(has_rule(hits, 'R1'), hits)
                self.assertEqual(len([h for h in hits if h.startswith('R1 ')]), 1)

    def test_r1_ignores_commented_import(self) -> None:
        hits = check_text(
            'lib/features/home/domain/entities/a.dart',
            'home',
            'domain',
            "// import 'package:flutter/material.dart';\n",
        )
        self.assertEqual(hits, [])

    def test_r2_supabase_outside_data(self) -> None:
        hits = check_text(
            'lib/features/notes/presentation/cubit/c.dart',
            'notes',
            'presentation',
            "import 'package:supabase_flutter/supabase_flutter.dart';\n",
        )
        self.assertTrue(has_rule(hits, 'R2'), hits)

    def test_r3_getit_import_and_locate_call(self) -> None:
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            "import 'package:get_it/get_it.dart';\n",
        )
        self.assertTrue(has_rule(hits, 'R3'), hits)
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            'final x = GetIt.instance<AuthService>();\n',
        )
        self.assertTrue(has_rule(hits, 'R3'), hits)

    def test_r3_getit_shorthand_locate_call(self) -> None:
        for line in (
            'final x = GetIt.I<AuthService>();\n',
            'final x = GetIt . I<AuthService>();\n',
        ):
            with self.subTest(line=line):
                hits = check_text(
                    'lib/features/people/presentation/views/v.dart',
                    'people',
                    'presentation',
                    line,
                )
                self.assertTrue(has_rule(hits, 'R3'), hits)
        # Commented-out locate calls are ignored.
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            '// final x = GetIt.I<AuthService>();\n',
        )
        self.assertFalse(has_rule(hits, 'R3'), hits)

    def test_r4_domain_reaches_into_other_feature_layers(self) -> None:
        for layer in ('data', 'application', 'presentation'):
            with self.subTest(layer=layer):
                hits = check_text(
                    'lib/features/home/domain/usecase/u.dart',
                    'home',
                    'domain',
                    'import '
                    f"'package:house_mira/features/people/{layer}/x.dart';\n",
                )
                self.assertTrue(has_rule(hits, 'R4'), hits)
        # Domain-to-domain sharing is allowed.
        hits = check_text(
            'lib/features/home/domain/usecase/u.dart',
            'home',
            'domain',
            "import 'package:house_mira/features/people/domain/entities/p.dart';\n",
        )
        self.assertFalse(has_rule(hits, 'R4'), hits)

    def test_r4_application_reaches_into_other_feature_layers(self) -> None:
        for layer in ('data', 'application', 'presentation'):
            with self.subTest(layer=layer):
                hits = check_text(
                    'lib/features/home/application/usecase/u.dart',
                    'home',
                    'application',
                    'import '
                    f"'package:house_mira/features/people/{layer}/x.dart';\n",
                )
                self.assertTrue(has_rule(hits, 'R4'), hits)
        # Application-to-domain sharing is allowed.
        hits = check_text(
            'lib/features/home/application/usecase/u.dart',
            'home',
            'application',
            "import 'package:house_mira/features/people/domain/entities/p.dart';\n",
        )
        self.assertFalse(has_rule(hits, 'R4'), hits)
        # Same-feature application imports stay allowed.
        hits = check_text(
            'lib/features/reminders/application/s.dart',
            'reminders',
            'application',
            'import '
            "'package:house_mira/features/reminders/domain/entities/r.dart';\n",
        )
        self.assertEqual(hits, [])

    def test_block_comments_are_ignored(self) -> None:
        # Single-line block comments hide locate calls and imports.
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            '/* final x = GetIt.instance<AuthService>(); */\n',
        )
        self.assertFalse(has_rule(hits, 'R3'), hits)
        hits = check_text(
            'lib/features/home/domain/entities/a.dart',
            'home',
            'domain',
            "/* import 'package:flutter/material.dart'; */\n",
        )
        self.assertFalse(has_rule(hits, 'R1'), hits)
        # Multi-line block comments hide everything until */.
        text = (
            '/*\n'
            'final x = GetIt.instance<AuthService>();\n'
            "import 'package:flutter/material.dart';\n"
            '*/\n'
            "import 'package:meta/meta.dart';\n"
        )
        hits = check_text(
            'lib/features/home/domain/entities/a.dart',
            'home',
            'domain',
            text,
        )
        self.assertEqual(hits, [])
        # Inline block comments leave the surrounding code checked.
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            '/* comment */ final x = GetIt.instance<AuthService>();\n',
        )
        self.assertTrue(has_rule(hits, 'R3'), hits)
        # Trailing // comments never flag a locate call.
        hits = check_text(
            'lib/features/people/presentation/views/v.dart',
            'people',
            'presentation',
            'final x = make(); // was GetIt.instance<AuthService>()\n',
        )
        self.assertFalse(has_rule(hits, 'R3'), hits)

    def test_r4_same_feature_domain_to_data_allowed_tech_debt(self) -> None:
        # Intra-feature domain->data (e.g. repository contracts taking
        # NoteModel/ReminderModel) is grandfathered tech debt, see
        # ADR-0006 consequences; R4 only guards cross-feature edges.
        hits = check_text(
            'lib/features/notes/domain/repository/r.dart',
            'notes',
            'domain',
            "import 'package:house_mira/features/notes/data/models/note_model.dart';\n",
        )
        self.assertFalse(has_rule(hits, 'R4'), hits)

    def test_r5_provider_import_in_feature(self) -> None:
        hits = check_text(
            'lib/features/notes/presentation/views/v.dart',
            'notes',
            'presentation',
            "import 'package:provider/provider.dart';\n",
        )
        self.assertTrue(has_rule(hits, 'R5'), hits)


if __name__ == '__main__':
    unittest.main()
