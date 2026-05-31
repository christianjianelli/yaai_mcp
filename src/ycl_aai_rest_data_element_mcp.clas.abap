CLASS ycl_aai_rest_data_element_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             name              TYPE yde_aai_fc_data_element,
             short_description TYPE as4text,
             domain_name       TYPE yde_aai_fc_domain,
             data_type         TYPE yde_aai_fc_data_type,
             length            TYPE yde_aai_fc_length,
             decimals          TYPE yde_aai_fc_decimals,
             label_short       TYPE scrtext_s,
             label_medium      TYPE scrtext_m,
             label_long        TYPE scrtext_l,
             label_heading     TYPE reptext,
             transport_request TYPE yde_aai_fc_transport_request,
             package           TYPE packname,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             name              TYPE yde_aai_fc_data_element,
             short_description TYPE as4text,
             domain_name       TYPE yde_aai_fc_domain,
             data_type         TYPE yde_aai_fc_data_type,
             length            TYPE yde_aai_fc_length,
             decimals          TYPE yde_aai_fc_decimals,
             label_short       TYPE scrtext_s,
             label_medium      TYPE scrtext_m,
             label_long        TYPE scrtext_l,
             label_heading     TYPE reptext,
             transport_request TYPE yde_aai_fc_transport_request,
           END OF ty_request_update_s,

           BEGIN OF ty_request_translation_s,
             name              TYPE yde_aai_fc_data_element,
             short_description TYPE as4text,
             label_short       TYPE scrtext_s,
             label_medium      TYPE scrtext_m,
             label_long        TYPE scrtext_l,
             label_heading     TYPE reptext,
             transport_request TYPE yde_aai_fc_transport_request,
             language          TYPE c LENGTH 2,
           END OF ty_request_translation_s.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_data_element_mcp IMPLEMENTATION.

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

    DATA(l_response) = NEW ycl_aai_fc_data_element_tools( )->create( i_data_element_name = ls_request-name
                                                                     i_short_description = ls_request-short_description
                                                                     i_domain_name       = ls_request-domain_name
                                                                     i_data_type         = ls_request-data_type
                                                                     i_length            = ls_request-length
                                                                     i_decimals          = ls_request-decimals
                                                                     i_label_short       = ls_request-label_short
                                                                     i_label_medium      = ls_request-label_medium
                                                                     i_label_long        = ls_request-label_long
                                                                     i_label_heading     = ls_request-label_heading
                                                                     i_transport_request = ls_request-transport_request
                                                                     i_package           = ls_request-package ).

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
          l_spras    TYPE sy-langu.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = lt_path_info[ 2 ].

    ENDIF.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    DATA(l_language) = i_o_request->get_form_field( name = 'language' ).

    IF l_action IS INITIAL.

      IF l_package IS INITIAL.

        l_response = NEW ycl_aai_fc_data_element_tools( )->read( i_data_element_name = CONV #( l_name ) ).

      ELSE.

        l_response = NEW ycl_aai_fc_data_element_tools( )->search( i_package = CONV #( l_package )
                                                                   i_data_element_name = CONV #( l_name )
                                                                   i_short_description = CONV #( l_description ) ).

      ENDIF.

      i_o_response->set_content_type( content_type = 'text/plain' ).

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    CASE l_action.

      WHEN 'GET_TRANSLATION'.

        CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
          EXPORTING
            input            = l_language
          IMPORTING
            output           = l_spras
          EXCEPTIONS
            unknown_language = 0
            OTHERS           = 0.

        l_response = NEW ycl_aai_fc_data_element_tools( )->get_translation( i_data_element_name = CONV #( l_name )
                                                                            i_language = l_spras ).

    ENDCASE.

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA: lt_path_info TYPE string_table.

    DATA: ls_request_update      TYPE ty_request_update_s,
          ls_request_translation TYPE ty_request_translation_s.

    DATA: l_action   TYPE string,
          l_response TYPE string,
          l_spras    TYPE sy-langu.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( condense( lt_path_info[ 2 ] ) ).

    ENDIF.

    DATA(l_body) = i_o_request->get_cdata( ).

    IF l_action IS INITIAL.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json        = l_body
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case
        CHANGING
          data        = ls_request_update
      ).

      IF ls_request_update IS INITIAL.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'Empty or invalid payload received'
        ).

        RETURN.

      ENDIF.

      l_response = NEW ycl_aai_fc_data_element_tools( )->update( i_data_element_name = ls_request_update-name
                                                                 i_short_description = ls_request_update-short_description
                                                                 i_domain_name       = ls_request_update-domain_name
                                                                 i_data_type         = ls_request_update-data_type
                                                                 i_length            = ls_request_update-length
                                                                 i_decimals          = ls_request_update-decimals
                                                                 i_label_short       = ls_request_update-label_short
                                                                 i_label_medium      = ls_request_update-label_medium
                                                                 i_label_long        = ls_request_update-label_long
                                                                 i_label_heading     = ls_request_update-label_heading
                                                                 i_transport_request = ls_request_update-transport_request ).

    ENDIF.

    CASE l_action.

      WHEN 'SET_TRANSLATION'.

        /ui2/cl_json=>deserialize(
        EXPORTING
          json        = l_body
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case
        CHANGING
          data        = ls_request_translation
      ).

        IF ls_request_translation IS INITIAL.

          i_o_response->set_status(
            EXPORTING
              code   = '400'
              reason = 'Empty or invalid payload received'
          ).

          RETURN.

        ENDIF.

        CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
          EXPORTING
            input            = ls_request_translation-language
          IMPORTING
            output           = l_spras
          EXCEPTIONS
            unknown_language = 0
            OTHERS           = 0.

        l_response = NEW ycl_aai_fc_data_element_tools( )->set_translation( i_data_element_name = ls_request_translation-name
                                                                            i_transport_request = ls_request_translation-transport_request
                                                                            i_language          = l_spras
                                                                            i_short_description = ls_request_translation-short_description
                                                                            i_label_short       = ls_request_translation-label_short
                                                                            i_label_medium      = ls_request_translation-label_medium
                                                                            i_label_long        = ls_request_translation-label_long
                                                                            i_label_heading     = ls_request_translation-label_heading ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    DATA(l_response) = NEW ycl_aai_fc_data_element_tools( )->delete( i_data_element_name = CONV #( l_name )
                                                                     i_transport_request = CONV #( l_transport_request ) ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
