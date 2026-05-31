CLASS ycl_aai_rest_table_type_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             name              TYPE yde_aai_fc_structure,
             short_description TYPE as4text,
             rowtype           TYPE ttrowtype,
             transport_request TYPE yde_aai_fc_transport_request,
             package           TYPE packname,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             name              TYPE yde_aai_fc_structure,
             short_description TYPE as4text,
             rowtype           TYPE ttrowtype,
             transport_request TYPE yde_aai_fc_transport_request,
           END OF ty_request_update_s.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_table_type_mcp IMPLEMENTATION.

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

    l_response = NEW ycl_aai_fc_table_type_tools( )->create( i_table_type_name   = ls_request-name
                                                             i_short_description = ls_request-short_description
                                                             i_rowtype           = ls_request-rowtype
                                                             i_transport_request = ls_request-transport_request
                                                             i_package           = ls_request-package ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~read.

    DATA l_response TYPE string.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    IF l_package IS INITIAL.

      l_response = NEW ycl_aai_fc_table_type_tools( )->read( i_table_type_name = CONV #( l_name ) ).

    ELSE.

      l_response = NEW ycl_aai_fc_table_type_tools( )->search( i_package           = CONV #( l_package )
                                                               i_table_type_name   = CONV #( l_name )
                                                               i_short_description = CONV #( l_description ) ).

    ENDIF.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA ls_request TYPE ty_request_update_s.

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

    l_response = NEW ycl_aai_fc_table_type_tools( )->update( i_table_type_name   = ls_request-name
                                                             i_short_description = ls_request-short_description
                                                             i_rowtype           = ls_request-rowtype
                                                             i_transport_request = ls_request-transport_request ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    DATA(l_response) = NEW ycl_aai_fc_table_type_tools( )->delete( i_table_type_name   = CONV #( l_name )
                                                                   i_transport_request = CONV #( l_transport_request ) ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
