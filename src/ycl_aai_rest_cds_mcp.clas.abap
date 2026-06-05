CLASS ycl_aai_rest_cds_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             name              TYPE ddlname,
             short_description TYPE as4text,
             transport_request TYPE yde_aai_fc_transport_request,
             package           TYPE packname,
             source            TYPE string,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             name              TYPE ddlname,
             short_description TYPE as4text,
             transport_request TYPE yde_aai_fc_transport_request,
             source            TYPE string,
           END OF ty_request_update_s.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_rest_cds_mcp IMPLEMENTATION.

  METHOD yif_aai_rest_resource~create.

    DATA ls_request TYPE ty_request_create_s.

    DATA l_response TYPE string.

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

    l_response = NEW ycl_aai_fc_cds_tools( )->create( i_name              = ls_request-name
                                                      i_short_description = ls_request-short_description
                                                      i_transport_request = ls_request-transport_request
                                                      i_package           = ls_request-package
                                                      i_source            = ls_request-source
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

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

      l_response = NEW ycl_aai_fc_cds_tools( )->read( i_name = CONV #( l_name ) ).

    ENDIF.

    CASE l_action.

      WHEN 'CHECK'.

        l_response = NEW ycl_aai_fc_cds_tools( )->check( i_name = CONV #( l_name ) ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA ls_request TYPE ty_request_create_s.

    DATA l_response TYPE string.

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

    l_response = NEW ycl_aai_fc_cds_tools( )->update( i_name              = ls_request-name
                                                      i_short_description = ls_request-short_description
                                                      i_transport_request = ls_request-transport_request
                                                      i_source            = ls_request-source ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA l_response TYPE string.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).
    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    l_response = NEW ycl_aai_fc_cds_tools( )->delete( i_name = CONV #( l_name )
                                                      i_transport_request = CONV #( l_transport_request ) ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
