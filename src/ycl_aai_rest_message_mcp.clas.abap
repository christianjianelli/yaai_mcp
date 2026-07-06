CLASS ycl_aai_rest_message_mcp DEFINITION INHERITING FROM ycl_aai_rest_base
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request_create_s,
             message_class     TYPE yde_aai_fc_message_class,
             message_number    TYPE symsgno,
             message_text      TYPE natxt,
             package           TYPE packname,
             transport_request TYPE yde_aai_fc_transport_request,
           END OF ty_request_create_s,

           BEGIN OF ty_request_update_s,
             message_class     TYPE yde_aai_fc_message_class,
             message_number    TYPE symsgno,
             message_text      TYPE natxt,
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



CLASS ycl_aai_rest_message_mcp IMPLEMENTATION.

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

    l_response = NEW ycl_aai_fc_message_class_tools( )->add_message( i_message_class     = ls_request-message_class
                                                                     i_message_number    = ls_request-message_number
                                                                     i_message_text      = ls_request-message_text
                                                                     i_transport_request = ls_request-transport_request ).

    i_o_response->set_content_type( content_type = 'text/plain' ).

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~read.

    DATA: l_response TYPE string,
          l_spras    TYPE spras.

    DATA(l_message_class) = to_upper( condense( i_o_request->get_form_field( name = 'message_class' ) ) ).

    DATA(l_message_number) = condense( i_o_request->get_form_field( name = 'message_number' ) ).

    DATA(l_language) = to_upper( condense( i_o_request->get_form_field( name = 'language' ) ) ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
      EXPORTING
        input            = l_language
      IMPORTING
        output           = l_spras
      EXCEPTIONS
        unknown_language = 1
        OTHERS           = 2.

    IF sy-subrc <> 0.

      l_response = |Unknown language { l_language }.|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    SELECT SINGLE arbgb, masterlang
      FROM t100a
      WHERE arbgb = @l_message_class
      INTO @DATA(ls_t100a).

    IF sy-subrc <> 0.

      l_response = |Message class { l_message_class } not found.|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    IF NOT l_message_number CO '0123456789'.

      l_response = |Invalid message number { l_message_number }. Expected: 000 to 999|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    IF l_spras = ls_t100a-masterlang.

      l_response = NEW ycl_aai_fc_message_class_tools( )->read_message( i_message_class     = CONV #( l_message_class )
                                                                        i_message_number    = CONV #( l_message_number ) ).
    ELSE.

      l_response = NEW ycl_aai_fc_message_class_tools( )->read_message( i_message_class     = CONV #( l_message_class )
                                                                        i_message_number    = CONV #( l_message_number )
                                                                        i_language          = l_spras ).
    ENDIF.

  ENDMETHOD.

  METHOD yif_aai_rest_resource~update.

    DATA ls_request TYPE ty_request_update_s.

    DATA: l_response TYPE string,
          l_spras    TYPE spras.

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

    i_o_response->set_content_type( content_type = 'text/plain' ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
      EXPORTING
        input            = ls_request-language
      IMPORTING
        output           = l_spras
      EXCEPTIONS
        unknown_language = 1
        OTHERS           = 2.

    IF sy-subrc <> 0.

      l_response = |Unknown language { ls_request-language }.|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    SELECT SINGLE arbgb, masterlang
      FROM t100a
      WHERE arbgb = @ls_request-message_class
      INTO @DATA(ls_t100a).

    IF sy-subrc <> 0.

      l_response = |Message class { ls_request-message_class } not found.|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    IF l_spras = ls_t100a-masterlang.

      l_response = NEW ycl_aai_fc_message_class_tools( )->update_message( i_message_class     = ls_request-message_class
                                                                          i_message_number    = ls_request-message_number
                                                                          i_message_text      = ls_request-message_text
                                                                          i_transport_request = ls_request-transport_request ).
    ELSE.

      l_response = NEW ycl_aai_fc_message_class_tools( )->set_translation( i_message_class     = ls_request-message_class
                                                                           i_message_number    = ls_request-message_number
                                                                           i_transport_request = ls_request-transport_request
                                                                           i_language          = l_spras
                                                                           i_message_text      = ls_request-message_text ).

    ENDIF.

    i_o_response->set_cdata(
      EXPORTING
        data = l_response
    ).

  ENDMETHOD.

  METHOD yif_aai_rest_resource~delete.

    DATA l_response TYPE string.

    DATA(l_message_class) = to_upper( condense( i_o_request->get_form_field( name = 'message_class' ) ) ).

    DATA(l_message_number) = condense( i_o_request->get_form_field( name = 'message_number' ) ).

    DATA(l_transport_request) = to_upper( condense( i_o_request->get_form_field( name = 'transport_request' ) ) ).

    IF NOT l_message_number CO '0123456789'.

      l_response = |Invalid message number { l_message_number }. Expected: 000 to 999|.

      i_o_response->set_cdata(
        EXPORTING
          data = l_response
      ).

      RETURN.

    ENDIF.

    l_response = NEW ycl_aai_fc_message_class_tools( )->delete_message( i_message_class     = CONV #( l_message_class )
                                                                        i_message_number    = CONV #( l_message_number )
                                                                        i_transport_request = CONV #( l_transport_request ) ).

  ENDMETHOD.

ENDCLASS.
