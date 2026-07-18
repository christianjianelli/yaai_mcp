CLASS ycl_aai_rest_transport_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             category    TYPE yde_aai_fc_transp_req_categ,
             description TYPE as4text,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             description TYPE as4text,
           END OF ty_request_update_s.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_transport_mcp IMPLEMENTATION.

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

    DATA(l_response) = NEW ycl_aai_fc_transport_tools( )->create(
      EXPORTING
        i_description      = ls_request-description
        i_request_category = ls_request-category
    ).

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

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    DATA(l_modifiable) = COND abap_bool( WHEN to_upper( i_o_request->get_form_field( name = 'modifiable' ) ) = 'TRUE'
                                         THEN abap_true
                                         ELSE abap_false ).

    DATA(l_released) = COND abap_bool( WHEN to_upper( i_o_request->get_form_field( name = 'released' ) ) = 'TRUE'
                                       THEN abap_true
                                       ELSE abap_false ).

    DATA(l_workbench) = COND abap_bool( WHEN to_upper( i_o_request->get_form_field( name = 'workbench' ) ) = 'TRUE'
                                        THEN abap_true
                                        ELSE abap_false ).

    DATA(l_customizing) = COND abap_bool( WHEN to_upper( i_o_request->get_form_field( name = 'customizing' ) ) = 'TRUE'
                                          THEN abap_true
                                          ELSE abap_false ).

    DATA(l_transport_of_copies) = COND abap_bool( WHEN to_upper( i_o_request->get_form_field( name = 'transport_of_copies' ) ) = 'TRUE'
                                                  THEN abap_true
                                                  ELSE abap_false ).

    DATA(l_object_type) = to_upper( condense( i_o_request->get_form_field( name = 'object_type' ) ) ).
    DATA(l_object_name) = to_upper( condense( i_o_request->get_form_field( name = 'object_name' ) ) ).


    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

      l_response = NEW ycl_aai_fc_transport_tools( )->read( CONV #( l_transport_request ) ).

    ENDIF.

    CASE l_action.

      WHEN 'SEARCH'.

        l_response = NEW ycl_aai_fc_transport_tools( )->search( i_modifiable          = l_modifiable
                                                                i_released            = l_released
                                                                i_workbench           = l_workbench
                                                                i_customizing         = l_customizing
                                                                i_transport_of_copies = l_transport_of_copies
                                                                i_description         = CONV #( l_description ) ).

      WHEN 'GET_CURRENT_TRANSPORT_REQUEST'.

        l_response = NEW ycl_aai_fc_transport_tools( )->get_current_transport_request(
                                                       i_object_type = CONV #( l_object_type )
                                                       i_object_name = CONV #( l_object_name )
                                                     ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

    ENDIF.

    CASE l_action.

      WHEN 'CHANGE_DESCRIPTION'.

        l_response = NEW ycl_aai_fc_transport_tools( )->change_description( i_transport_request = CONV #( l_transport_request )
                                                                            i_description = CONV #( l_description ) ).

      WHEN 'RELEASE'.

        l_response = NEW ycl_aai_fc_transport_tools( )->release( i_transport_request = CONV #( l_transport_request ) ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
