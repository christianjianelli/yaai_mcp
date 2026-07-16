CLASS ycl_aai_rest_abap_activate_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_mass_activation_s,
             objects TYPE ytt_aai_fc_object_activation,
           END OF ty_request_mass_activation_s.

    METHODS yif_aai_rest_resource~read REDEFINITION.

    METHODS yif_aai_rest_resource~update REDEFINITION.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS ycl_aai_rest_abap_activate_mcp IMPLEMENTATION.

  METHOD yif_aai_rest_resource~read.

    DATA lt_path_info TYPE string_table.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    CASE l_action.

      WHEN 'GET_ALLOWED_OBJECT_TYPES' OR space.

        l_response = NEW ycl_aai_fc_abap_activate( )->get_allowed_object_types( ).

      WHEN OTHERS.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = |Invalid action `{ l_action }` informed in the path info { l_path_info }.|
        ).

        RETURN.

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA lt_path_info TYPE string_table.

    DATA ls_request TYPE ty_request_mass_activation_s.

    DATA: l_action   TYPE string,
          l_response TYPE string.

    DATA(l_path_info) = i_o_request->get_header_field( name = '~path_info' ).

    SHIFT l_path_info LEFT BY 1 PLACES.

    SPLIT l_path_info AT '/' INTO TABLE lt_path_info.

    IF lines( lt_path_info ) > 1.

      "The second URL parameter is expected to be the action identifier
      l_action = to_upper( lt_path_info[ 2 ] ).

    ENDIF.

    DATA(l_body) = i_o_request->get_cdata( ).

    /ui2/cl_json=>deserialize(
      EXPORTING
        json        = l_body
        pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING
        data        = ls_request
    ).

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    CASE l_action.

      WHEN 'MASS_ACTIVATION'.

        IF ls_request IS INITIAL.

          i_o_response->set_status(
            EXPORTING
              code   = '400'
              reason = 'Empty or invalid payload received'
          ).

          RETURN.

        ENDIF.

        LOOP AT ls_request-objects ASSIGNING FIELD-SYMBOL(<ls_object>).
          <ls_object>-object = to_upper( condense( <ls_object>-object ) ).
          <ls_object>-obj_name = to_upper( condense( <ls_object>-obj_name ) ).
        ENDLOOP.

        l_response = NEW ycl_aai_fc_abap_activate( )->mass_activation( ls_request-objects ).

      WHEN 'MASS_ACTIVATION_FOR_TRANSPORT_REQUEST'.

        IF l_transport_request IS INITIAL.

          i_o_response->set_status(
            EXPORTING
              code   = '400'
              reason = 'No transport request informed.'
          ).

          RETURN.

        ENDIF.

        l_response = NEW ycl_aai_fc_abap_activate( )->mass_activation_transp_request( CONV #( l_transport_request ) ).

      WHEN OTHERS.

        i_o_response->set_status(
          EXPORTING
            code   = '400'
            reason = 'No activation option informed.'
        ).

        RETURN.

    ENDCASE.

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

ENDCLASS.
