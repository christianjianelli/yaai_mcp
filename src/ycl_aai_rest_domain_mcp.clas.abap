CLASS ycl_aai_rest_domain_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~create REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

    METHODS yif_aai_rest_resource~delete REDEFINITION.

    TYPES: BEGIN OF ty_request_create_s,
             name              TYPE yde_aai_fc_domain,
             short_description TYPE as4text,
             data_type         TYPE yde_aai_fc_data_type,
             length            TYPE yde_aai_fc_length,
             decimals          TYPE yde_aai_fc_decimals,
             case_sensitive    TYPE yde_aai_fc_case_sensitive,
             transport_request TYPE yde_aai_fc_transport_request,
             package           TYPE packname,
             fixed_values      TYPE ytt_aai_fc_domain_fixed_val,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             name              TYPE yde_aai_fc_domain,
             short_description TYPE as4text,
             data_type         TYPE yde_aai_fc_data_type,
             length            TYPE yde_aai_fc_length,
             decimals          TYPE yde_aai_fc_decimals,
             case_sensitive    TYPE yde_aai_fc_case_sensitive,
             transport_request TYPE yde_aai_fc_transport_request,
             fixed_values      TYPE ytt_aai_fc_domain_fixed_val,
           END OF ty_request_update_s,

           BEGIN OF ty_request_translation_s,
             name              TYPE yde_aai_fc_domain,
             language          TYPE c LENGTH 2,
             short_description TYPE as4text,
             transport_request TYPE yde_aai_fc_transport_request,
             fixed_values      TYPE ytt_aai_fc_domain_fixed_val,
           END OF ty_request_translation_s.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_rest_domain_mcp IMPLEMENTATION.

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

    DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

    DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

    DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

    DATA(l_language) = i_o_request->get_form_field( name = 'language' ).

    IF l_action IS INITIAL.

      IF l_package IS INITIAL.

        l_response = NEW ycl_aai_fc_domain_tools( )->read( i_domain_name = CONV #( l_name ) ).

      ELSE.

        l_response = NEW ycl_aai_fc_domain_tools( )->search( i_package = CONV #( l_package )
                                                             i_domain_name = CONV #( l_name )
                                                             i_short_description = CONV #( l_description ) ).

      ENDIF.

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

        l_response = NEW ycl_aai_fc_domain_tools( )->get_translation(
                                                    i_domain_name = CONV #( l_name )
                                                    i_language    = l_spras ).

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

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

    DATA(l_response) = NEW ycl_aai_fc_domain_tools( )->create(
      EXPORTING
        i_domain_name       = ls_request-name
        i_short_description = ls_request-short_description
        i_data_type         = ls_request-data_type
        i_length            = ls_request-length
        i_decimals          = ls_request-decimals
        i_case_sensitive    = ls_request-case_sensitive
        i_transport_request = ls_request-transport_request
        i_package           = ls_request-package
        i_t_fixed_values    = ls_request-fixed_values
    ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA lt_path_info TYPE string_table.

    DATA: ls_request_update      TYPE ty_request_update_s,
          ls_request_translation TYPE ty_request_translation_s.

    DATA: l_action TYPE string,
          l_spras  TYPE spras.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

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

      DATA(l_response) = NEW ycl_aai_fc_domain_tools( )->update(
        EXPORTING
          i_domain_name       = ls_request_update-name
          i_short_description = ls_request_update-short_description
          i_data_type         = ls_request_update-data_type
          i_length            = ls_request_update-length
          i_decimals          = ls_request_update-decimals
          i_case_sensitive    = ls_request_update-case_sensitive
          i_transport_request = ls_request_update-transport_request
          i_t_fixed_values    = ls_request_update-fixed_values
      ).

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

        l_response = NEW ycl_aai_fc_domain_tools( )->set_translation( i_domain_name       = ls_request_translation-name
                                                                      i_transport_request = ls_request_translation-transport_request
                                                                      i_language          = l_spras
                                                                      i_short_description = ls_request_translation-short_description
                                                                      i_t_fixed_values    = ls_request_translation-fixed_values ).

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

    DATA(l_response) = NEW ycl_aai_fc_domain_tools( )->delete( i_domain_name       = CONV #( l_name )
                                                               i_transport_request = CONV #( l_transport_request ) ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA(ls_request) = VALUE ty_request_create_s( name = 'ZDO_GENDER'
                                                  short_description = 'Gender domain'
                                                  data_type = 'CHAR'
                                                  length = '1'
                                                  decimals = 0
                                                  case_sensitive = space
                                                  transport_request = 'NPLK900136'
                                                  package = 'ZTKN001'
                                                  fixed_values = VALUE #( ( value = 'M' description = 'Male' )
                                                                          ( value = 'F' description = 'Female' )
                                                                          ( value = ' ' description = 'Not informed' ) ) ).
    DATA(l_json) = /ui2/cl_json=>serialize(
          EXPORTING
            data             = ls_request                 " Data to serialize
*            compress         =                  " Skip empty elements
*            name             =                  " Object name
            pretty_name      = /ui2/cl_json=>pretty_mode-camel_case                 " Pretty Print property names
*            type_descr       =                  " Data descriptor
*            assoc_arrays     =                  " Serialize tables with unique keys as associative array
*            ts_as_iso8601    =                  " Dump timestamps as string in ISO8601 format
*            expand_includes  =                  " Expand named includes in structures
*            assoc_arrays_opt =                  " Optimize rendering of name value maps
*            numc_as_string   =                  " Serialize NUMC fields as strings
*            name_mappings    =                  " ABAP<->JSON Name Mapping Table
*            conversion_exits =                  " Use DDIC conversion exits on serialize of values
        ).

    out->write( l_json ).


  ENDMETHOD.

ENDCLASS.
