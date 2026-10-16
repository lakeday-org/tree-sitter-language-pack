#![allow(clippy::unwrap_used, clippy::expect_used)]

use tree_sitter_language_pack::{ProcessConfig, QueryKind, StructureKind, get_parser, get_query, process};

const HIVE_DDL: &str = include_str!("fixtures/hive_template.sql");

fn assert_valid_sql(source: &str) -> String {
    let result = process(source, &ProcessConfig::new("sql"))
        .expect("SQL grammar required; build with TSLP_LANGUAGES=sql,jinja2");
    assert_eq!(result.language, "sql");
    assert_eq!(result.metrics.error_count, 0, "{source}");
    let tree = get_parser("sql").unwrap().parse(source).unwrap();
    assert!(!tree.root_node().has_error(), "{source}");
    assert_eq!(tree.root_node().end_byte(), source.len());
    tree.root_node().to_sexp()
}

#[test]
fn should_parse_complete_hive_ddl_and_preserve_table_declaration() {
    assert_valid_sql(HIVE_DDL);
    let result = process(HIVE_DDL, &ProcessConfig::new("sql")).unwrap();
    assert_eq!(result.structure.len(), 1);
    assert_eq!(result.structure[0].name.as_deref(), Some("t"));
    assert_eq!(result.structure[0].kind, StructureKind::Struct);
}

#[test]
fn should_parse_hive_ddl_after_rendering_quoted_template() {
    assert_valid_sql(&HIVE_DDL.replace("{{bucket}}", "fixture-bucket"));
}

#[test]
fn should_preserve_nested_array_element_types() {
    let ast = assert_valid_sql("CREATE TABLE t(a array<array<string>>);");
    assert_eq!(ast.matches("(array_type").count(), 2);
}

#[test]
fn should_preserve_serde_and_explicit_storage_format_fields() {
    let ast = assert_valid_sql(
        "CREATE TABLE t(a string) ROW FORMAT SERDE 'serializer' \
         STORED AS INPUTFORMAT 'reader' OUTPUTFORMAT 'writer';",
    );
    for field in ["serde_class:", "input_format:", "output_format:"] {
        assert!(ast.contains(field), "missing {field}: {ast}");
    }
}

#[test]
fn should_preserve_existing_partition_and_delimited_syntax() {
    for source in [
        "CREATE EXTERNAL TABLE t(a string) PARTITIONED BY (p string) STORED AS PARQUET;",
        "CREATE TABLE t(a string) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\\n';",
    ] {
        assert_valid_sql(source);
    }
}

#[test]
fn should_report_errors_for_incomplete_hive_type_or_format() {
    for source in [
        "CREATE TABLE t(a array<>);",
        "CREATE TABLE t(a string) STORED AS INPUTFORMAT 'reader';",
    ] {
        let result = process(source, &ProcessConfig::new("sql")).unwrap();
        assert!(result.metrics.error_count > 0, "{source}");
        assert!(
            get_parser("sql")
                .unwrap()
                .parse(source)
                .unwrap()
                .root_node()
                .has_error()
        );
    }
}

#[test]
fn should_compile_both_bundled_sql_queries() {
    for kind in [QueryKind::Highlights, QueryKind::Indents] {
        assert!(get_query("sql", kind).unwrap().is_some(), "required query: {kind:?}");
    }
}

#[test]
fn should_preserve_external_table_declarations_without_hive_clauses() {
    for source in ["CREATE TABLE t(a string);", "CREATE EXTERNAL TABLE t(a string);"] {
        assert_valid_sql(source);
        let result = process(source, &ProcessConfig::new("sql")).unwrap();
        assert_eq!(result.structure.len(), 1, "{source}");
        assert_eq!(result.structure[0].name.as_deref(), Some("t"));
        assert_eq!(result.structure[0].kind, StructureKind::Struct);
    }
}
