#![allow(clippy::unwrap_used, clippy::expect_used)]

use tree_sitter_language_pack::{ProcessConfig, detect_language, get_parser, process};

fn template_ast(source: &str) -> String {
    let result = process(source, &ProcessConfig::new("jinja2"))
        .expect("Jinja2 grammar required; build with TSLP_LANGUAGES=sql,jinja2");
    assert_eq!(result.language, "jinja2");
    assert_eq!(result.metrics.error_count, 0, "{source}");
    let tree = get_parser("jinja2").unwrap().parse(source).unwrap();
    assert!(!tree.root_node().has_error(), "{source}");
    assert_eq!(tree.root_node().end_byte(), source.len());
    tree.root_node().to_sexp()
}

#[test]
fn should_preserve_bare_variables_as_identifier_nodes() {
    for source in ["{{bucket}}", "{{ _bucket42 }}"] {
        assert_eq!(template_ast(source), "(source_file (identifier))");
    }
}

#[test]
fn should_parse_quoted_placeholder_in_complete_hive_template() {
    assert_eq!(
        template_ast(include_str!("fixtures/hive_template.sql")),
        "(source_file (identifier))"
    );
}

#[test]
fn should_preserve_nested_calls_containers_and_literal_nodes() {
    for (source, fragment) in [
        (
            "{{ outer(inner(bucket), suffix=region) }}",
            "(kwarg key: (identifier) value: (identifier))",
        ),
        (
            "{{ [{'bucket': bucket}, [region, 3]] }}",
            "(list (identifier) (integer))",
        ),
        (
            "{{ config(bucket, True, False, 'literal', 1, 1.5) }}",
            "(bool) (bool) (lit_string) (integer) (float)",
        ),
        (
            "SELECT '{{bucket}}' AS a, '{{region}}' AS b",
            "(identifier) (identifier)",
        ),
    ] {
        assert!(template_ast(source).contains(fragment), "{source}");
    }
}

#[test]
fn should_report_errors_for_malformed_template_delimiters() {
    for source in ["{{ bucket", "{{ outer(bucket }}", "{{ [bucket, {'key': region] }}"] {
        let result = process(source, &ProcessConfig::new("jinja2")).unwrap();
        assert!(result.metrics.error_count > 0, "{source}");
        assert!(
            get_parser("jinja2")
                .unwrap()
                .parse(source)
                .unwrap()
                .root_node()
                .has_error()
        );
    }
}

#[test]
fn should_keep_unsupported_template_operators_visible_as_errors() {
    for source in ["{{ bucket + 2 }}", "{{ config.bucket }}", "{{ bucket | upper }}"] {
        let result = process(source, &ProcessConfig::new("jinja2")).unwrap();
        assert!(result.metrics.error_count > 0, "{source}");
    }
}

#[test]
fn should_treat_raw_sql_as_text_without_claiming_sql_validation() {
    assert_eq!(
        template_ast("CREATE EXTERNAL TABLE ; ROW FORMAT SERDE ;"),
        "(source_file)"
    );
}

#[test]
fn should_select_existing_jinja2_language_for_both_compound_extensions() {
    for path in ["queries/table.j2.sql", "queries/table.sql.j2"] {
        assert_eq!(detect_language(path), Some("jinja2"));
    }
}
