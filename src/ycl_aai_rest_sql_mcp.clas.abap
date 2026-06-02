CLASS ycl_aai_rest_sql_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_sql_operation TYPE c LENGTH 6.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

    METHODS constructor.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA: _insert_whitelist TYPE RANGE OF yde_aai_fc_database_table,
          _read_whitelist   TYPE RANGE OF yde_aai_fc_database_table,
          _update_whitelist TYPE RANGE OF yde_aai_fc_database_table,
          _delete_whitelist TYPE RANGE OF yde_aai_fc_database_table.

    METHODS _is_authorized
      IMPORTING
                i_table_name        TYPE csequence
                i_operation         TYPE ty_sql_operation
      RETURNING VALUE(r_authorized) TYPE abap_bool.

ENDCLASS.



CLASS ycl_aai_rest_sql_mcp IMPLEMENTATION.

  METHOD constructor.

    super->constructor( ).

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'MCP_SQL_READ_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_insert_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'MCP_SQL_INSERT_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_read_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'MCP_SQL_UPDATE_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_update_whitelist.

    SELECT sign, opti AS option, low, high
      FROM tvarvc
      WHERE name = 'MCP_SQL_DELETE_WHITELIST'
      INTO CORRESPONDING FIELDS OF TABLE @me->_delete_whitelist.

  ENDMETHOD.

  METHOD yif_aai_rest_resource~create.

    FIELD-SYMBOLS <ls_record> TYPE any.

    DATA ls_record TYPE REF TO data.

    DATA l_response TYPE string.

    DATA(l_table) = to_upper( condense( i_o_request->get_form_field( name = 'table' ) ) ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'INSERT' ) = abap_false.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = |You are not authorized to insert entries into table { l_table }.|
      ).

      RETURN.

    ENDIF.

    DATA(l_body) = i_o_request->get_cdata( ).

    IF l_body IS INITIAL.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = 'Empty payload received.'
      ).

      RETURN.

    ENDIF.

    TRY.

        CREATE DATA ls_record TYPE (l_table).

      CATCH cx_sy_create_data_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    TRY.

        ASSIGN ls_record->* TO <ls_record>.

      CATCH cx_sy_assign_cast_illegal_cast
            cx_sy_assign_cast_unknown_type
            cx_sy_assign_out_of_range ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    /ui2/cl_json=>deserialize(
      EXPORTING
        json = l_body
      CHANGING
        data = <ls_record>
    ).

    IF <ls_record> IS INITIAL.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = 'Invalid payload received.'
      ).

      RETURN.

    ENDIF.

    TRY.

        INSERT INTO (l_table) VALUES @<ls_record>.

        IF sy-dbcnt > 0.
          l_response = |Success. { sy-dbcnt } records inserted.|.
        ELSE.
          l_response = |Insert failed. { sy-dbcnt } records inserted.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = |Error. 0 records inserted.|
        ).

        RETURN.

    ENDTRY.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~read.

    FIELD-SYMBOLS <lt_records> TYPE ANY TABLE.

    DATA lt_records TYPE REF TO data.

    DATA l_response TYPE string.

    DATA(l_fieldlist) = to_upper( i_o_request->get_form_field( name = 'fieldlist' ) ).
    DATA(l_table) = to_upper( condense( i_o_request->get_form_field( name = 'table' ) ) ).
    DATA(l_where) = i_o_request->get_form_field( name = 'where' ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'READ' ) = abap_false.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = |You are not authorized to read entries from table { l_table }.|
      ).

      RETURN.

    ENDIF.

    TRY.

        CREATE DATA lt_records TYPE TABLE OF (l_table).

      CATCH cx_sy_create_data_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    TRY.

        ASSIGN lt_records->* TO <lt_records>.

      CATCH cx_sy_assign_cast_illegal_cast
            cx_sy_assign_cast_unknown_type
            cx_sy_assign_out_of_range ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    TRY.

        SELECT (l_fieldlist) FROM (l_table) WHERE (l_where) INTO CORRESPONDING FIELDS OF TABLE @<lt_records>.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    l_response = /ui2/cl_json=>serialize(
      EXPORTING
        data = <lt_records>
    ).

    i_o_response->set_content_type( content_type = 'application/json' ).

    l_response = '{"records":' && l_response && '}'.

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA l_response TYPE string.

    DATA(l_table) = to_upper( condense( i_o_request->get_form_field( name = 'table' ) ) ).
    DATA(l_fieldlist) = i_o_request->get_form_field( name = 'fieldlist' ).
    DATA(l_where) = i_o_request->get_form_field( name = 'where' ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'UPDATE' ) = abap_false.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = |You are not authorized to update entries in table { l_table }.|
      ).

      RETURN.

    ENDIF.

    TRY.

        UPDATE (l_table) SET (l_fieldlist) WHERE (l_where).

        IF sy-dbcnt > 0.
          l_response = |Success. { sy-dbcnt } record(s) updated.|.
        ELSE.
          l_response = |Update failed. { sy-dbcnt } record(s) updated.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).


  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA l_response TYPE string.

    DATA(l_table) = to_upper( condense( i_o_request->get_form_field( name = 'table' ) ) ).
    DATA(l_where) = i_o_request->get_form_field( name = 'where' ).

    IF me->_is_authorized( i_table_name = l_table
                           i_operation  = 'DELETE' ) = abap_false.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = |You are not authorized to delete entries from table { l_table }.|
      ).

      RETURN.

    ENDIF.

    TRY.

        DELETE FROM (l_table) WHERE (l_where).

        IF sy-dbcnt > 0.
          l_response = |Success. { sy-dbcnt } record(s) deleted.|.
        ELSE.
          l_response = |Insert failed. { sy-dbcnt } record(s) deleted.|.
        ENDIF.

      CATCH cx_sy_dynamic_osql_error ##NO_HANDLER.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Tool execution failed.'
        ).

        RETURN.

    ENDTRY.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD _is_authorized.

    r_authorized = COND #( WHEN i_operation = 'INSERT' AND i_table_name IN me->_insert_whitelist THEN abap_true
                           WHEN i_operation = 'READ'   AND i_table_name IN me->_read_whitelist   THEN abap_true
                           WHEN i_operation = 'UPDATE' AND i_table_name IN me->_update_whitelist THEN abap_true
                           WHEN i_operation = 'DELETE' AND i_table_name IN me->_delete_whitelist THEN abap_true
                           ELSE abap_false ).

  ENDMETHOD.

ENDCLASS.
