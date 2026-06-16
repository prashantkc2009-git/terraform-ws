resource "aws_lakeformation_data_lake_settings" "main" {
  admins = var.admin_arns
}

resource "aws_lakeformation_permissions" "database" {
  for_each = var.database_permissions

  principal   = each.value.principal
  permissions = each.value.permissions

  database {
    name = each.value.database_name
  }
}

resource "aws_lakeformation_permissions" "table" {
  for_each = var.table_permissions

  principal   = each.value.principal
  permissions = each.value.permissions

  table {
    database_name = each.value.database_name
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "table_cell_filter" {
  for_each = var.cell_level_permissions

  principal   = each.value.principal
  permissions = each.value.permissions

  table_with_columns {
    database_name = each.value.database_name
    name          = each.value.table_name
    column_names  = each.value.column_names

    dynamic "cell_filter" {
      for_each = each.value.row_filter_expression != null ? [1] : []
      content {
        filter_expression = each.value.row_filter_expression
      }
    }
  }
}
