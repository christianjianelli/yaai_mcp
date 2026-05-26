CLASS ycl_aai_rest_domain_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS yif_aai_rest_resource~read REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_rest_domain_mcp IMPLEMENTATION.

  METHOD yif_aai_rest_resource~read.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = lt_path_info[ 2 ].

    ENDIF.

    IF l_action IS INITIAL.

      DATA(l_name) = to_upper( condense( i_o_request->get_form_field( name = 'name' ) ) ).

      DATA(l_package) = to_upper( condense( i_o_request->get_form_field( name = 'package' ) ) ).

      DATA(l_description) = i_o_request->get_form_field( name = 'description' ).

      IF l_package IS INITIAL.

        l_response = NEW ycl_aai_fc_domain_tools( )->read( i_domain_name = CONV #( l_name ) ).

      ELSE.

        l_response = NEW ycl_aai_fc_domain_tools( )->search( i_package = CONV #( l_package )
                                                             i_domain_name = CONV #( l_name )
                                                             i_short_description = CONV #( l_description ) ).

      ENDIF.

      i_o_response->set_content_type( content_type = 'text/plain' ).

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
