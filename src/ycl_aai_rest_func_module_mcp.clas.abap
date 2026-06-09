CLASS ycl_aai_rest_func_module_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS yif_aai_rest_resource~read REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_func_module_mcp IMPLEMENTATION.

  METHOD yif_aai_rest_resource~read.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

      l_response = NEW ycl_aai_fc_func_module_tools( )->read( i_function_module = CONV #( l_name ) ).

    ENDIF.

    CASE l_action.

      WHEN 'CHECK'.



    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
