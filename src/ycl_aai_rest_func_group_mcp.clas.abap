CLASS ycl_aai_rest_func_group_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             name              TYPE rs38l_area,
             short_description TYPE as4text,
             transport_request TYPE yde_aai_fc_transport_request,
             package           TYPE packname,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             function_group    TYPE rs38l_area,
             short_description TYPE as4text,
             transport_request TYPE yde_aai_fc_transport_request,
             source_code       TYPE string,
           END OF ty_request_update_s.

    METHODS yif_aai_rest_resource~create REDEFINITION.
    METHODS yif_aai_rest_resource~read REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_func_group_mcp IMPLEMENTATION.

  METHOD yif_aai_rest_resource~create.

    DATA ls_request TYPE ty_request_create_s.

    DATA(l_body) = i_o_request->get_cdata( ).

    /ui2/cl_json=>deserialize(
      EXPORTING
        json        = l_body
        pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING
        data        = ls_request
    ).

    IF ls_request IS INITIAL.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = 'Empty or invalid payload received'
      ).

      RETURN.

    ENDIF.

    DATA(l_response) = NEW ycl_aai_fc_func_group_tools( )->create( i_function_group_name = ls_request-name
                                                                   i_short_description = ls_request-short_description
                                                                   i_transport_request = ls_request-transport_request
                                                                   i_package = ls_request-package ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~read.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

      IF l_package IS INITIAL.

        l_response = NEW ycl_aai_fc_func_group_tools( )->read( i_function_group_name = CONV #( l_name ) ).

      ELSE.

        l_response = NEW ycl_aai_fc_func_group_tools( )->search( i_package             = CONV #( l_package )
                                                                 i_function_group_name = CONV #( l_name )
                                                                 i_short_description   = CONV #( l_description ) ).
      ENDIF.

    ENDIF.

    CASE l_action.

      WHEN 'CHECK'.

*        l_response = NEW ycl_aai_fc_func_group_tools( )->check_syntax( i_function_group_name = CONV #( l_name ) ).

      WHEN 'ACTIVATE'.

*        l_response = NEW ycl_aai_fc_func_group_tools( )->activate( i_function_group_name = CONV #( l_name ) ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.


ENDCLASS.
