CLASS ycl_aai_rest_transaction_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             transaction_code  TYPE tcode,
             short_description TYPE ttext_stct,
             program           TYPE programm,
             screen_number     TYPE scradnum,
             package           TYPE packname,
             transport_request TYPE yde_aai_fc_transport_request,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             transaction_code  TYPE tcode,
             short_description TYPE ttext_stct,
             language          TYPE c LENGTH 2,
             transport_request TYPE yde_aai_fc_transport_request,
           END OF ty_request_update_s.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_transaction_mcp IMPLEMENTATION.

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

    IF ls_request-screen_number IS NOT INITIAL.

      l_response = NEW ycl_aai_fc_transaction_tools( )->create_dialog_transaction( i_transaction_code  = ls_request-transaction_code
                                                                                   i_short_description = ls_request-short_description
                                                                                   i_program           = ls_request-program
                                                                                   i_screen_number     = ls_request-screen_number
                                                                                   i_package           = ls_request-package
                                                                                   i_transport_request = ls_request-transport_request ).

    ELSE.

      l_response = NEW ycl_aai_fc_transaction_tools( )->create_report_transaction( i_transaction_code  = ls_request-transaction_code
                                                                                   i_short_description = ls_request-short_description
                                                                                   i_program           = ls_request-program
                                                                                   i_package           = ls_request-package
                                                                                   i_transport_request = ls_request-transport_request ).

    ENDIF.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~read.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string,
          l_spras    TYPE spras.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    DATA(l_transaction_code) = to_upper( condense( i_o_request->get_form_field( name = 'transaction_code' ) ) ).

    DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    IF l_action IS INITIAL.

      IF l_package IS INITIAL.

        l_response = NEW ycl_aai_fc_transaction_tools( )->read( i_transaction_code = CONV #( l_transaction_code ) ).

      ELSE.

        l_response = NEW ycl_aai_fc_transaction_tools( )->search( i_package = CONV #( l_package )
                                                                  i_transaction_code = CONV #( l_transaction_code )
                                                                  i_short_description = CONV #( l_description ) ).

      ENDIF.

    ENDIF.

    CASE l_action.

      WHEN 'GET_TRANSLATION'.

        DATA(l_language) = to_upper( condense( i_o_request->get_form_field( name = 'language' ) ) ).

        CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
          EXPORTING
            input            = l_language
          IMPORTING
            output           = l_spras
          EXCEPTIONS
            unknown_language = 0
            OTHERS           = 0.

        l_response = NEW ycl_aai_fc_transaction_tools( )->get_translation( i_transaction_code = CONV #( l_transaction_code )
                                                                           i_language         = l_spras ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA lt_path_info TYPE string_table.

    DATA ls_request TYPE ty_request_update_s.

    DATA: l_action   TYPE string,
          l_response TYPE string,
          l_spras    TYPE spras.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    IF l_action IS INITIAL.

      i_o_response->set_status(
        EXPORTING
          code   = '400'
          reason = 'Empty action received'
      ).

      RETURN.

    ENDIF.

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

    CASE l_action.

      WHEN 'GET_TRANSLATION'.

        DATA(l_language) = to_upper( condense( i_o_request->get_form_field( name = 'language' ) ) ).

        CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
          EXPORTING
            input            = ls_request-language
          IMPORTING
            output           = l_spras
          EXCEPTIONS
            unknown_language = 0
            OTHERS           = 0.

        l_response = NEW ycl_aai_fc_transaction_tools( )->set_translation( i_transaction_code  = ls_request-transaction_code
                                                                           i_short_description = CONV #( ls_request-short_description )
                                                                           i_transport_request = ls_request-transport_request
                                                                           i_language          = l_spras ).
      WHEN OTHERS.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Invalid action received'
        ).

        RETURN.

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA l_response TYPE string.

    DATA(l_transaction_code) = to_upper( condense( i_o_request->get_form_field( name = 'transaction_code' ) ) ).

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    l_response = NEW ycl_aai_fc_transaction_tools( )->delete( i_transaction_code  = CONV #( l_transaction_code )
                                                              i_transport_request = CONV #( l_transport_request ) ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
