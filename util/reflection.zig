inline for(@typeInfo(@TypeOf(result_struct)).Struct.fields)|field|{
  if (std.mem.eql(u8, field.name, sql_result_field)){
    @field(result_struct, field.name) = sql_result_field_value;
  }
}
