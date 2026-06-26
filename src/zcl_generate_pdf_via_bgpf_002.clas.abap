CLASS zcl_generate_pdf_via_bgpf_002 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_serializable_object .
    INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .

    TYPES : BEGIN OF ts_salesorderid,
              salesorderid TYPE zreusei_salesorder_002_ads-SalesorderID,
            END OF ts_salesorderid.

    TYPES : tt_salesorderid TYPE STANDARD TABLE OF ts_salesorderid WITH DEFAULT KEY.


    METHODS constructor
      IMPORTING i_salesorders TYPE tt_salesorderid .

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA salesorders TYPE tt_salesorderid .
ENDCLASS.



CLASS ZCL_GENERATE_PDF_VIA_BGPF_002 IMPLEMENTATION.


  METHOD constructor.
    salesorders = i_salesorders.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.

    TYPES: BEGIN OF ty_longtext,
             msgv1(50),
             msgv2(50),
             msgv3(50),
             msgv4(50),
           END OF ty_longtext.

    DATA: ls_longtext TYPE ty_longtext.

    DATA update TYPE TABLE FOR UPDATE ZREUSER_SalesOrderTP_002\\SalesOrder.
    DATA update_line TYPE STRUCTURE FOR UPDATE ZREUSER_SalesOrderTP_002\\SalesOrder .
    DATA pdf_lib TYPE REF TO  zreuse_cl_generate_pdf.
    DATA error_message TYPE string.

    "get salesorder(s)

    pdf_lib  = NEW zreuse_cl_generate_pdf( ).

    LOOP AT salesorders INTO DATA(salesorder).
      IF pdf_lib->error_message_initialization IS INITIAL.
        pdf_lib->generate_pdf(
          EXPORTING
            iv_value      = CONV #( salesorder-SalesorderID )
          IMPORTING
            my_pdf        = DATA(my_pdf)
            error_message = error_message
        ).
      ELSE.
        error_message = pdf_lib->error_message_initialization.
      ENDIF.
      IF error_message IS NOT INITIAL.
        update_line-Description = error_message.
      ELSE.
        update_line-Description = 'success'.
        update_line-Attachment = my_pdf.
        update_line-filename = |file_{ salesorder-SalesorderID }.pdf|.
        update_line-MimeType = 'application/pdf'.
      ENDIF.
      update_line-SalesorderID      = salesorder-SalesorderID.
      update_line-%is_draft   = if_abap_behv=>mk-off.
      APPEND update_line TO update.
    ENDLOOP.

    MODIFY ENTITIES OF ZREUSER_SalesOrderTP_002
    ENTITY SalesOrder
      UPDATE FIELDS (
                      Description
                      Attachment
                      FileName
                      MimeType
                      ) WITH update

              MAPPED DATA(mapped)
              FAILED DATA(failed)
              REPORTED DATA(reported).


    "persist changes
    COMMIT ENTITIES
      RESPONSE OF ZREUSER_SalesOrderTP_002
      FAILED DATA(failed_commit)
      REPORTED DATA(reported_commit).

   " Raise Event
   DATA(ptab) = VALUE abap_parmbind_tab( ( name = 'I_SALESORDERID' kind = cl_abap_objectdescr=>exporting value = REF #( salesorder-SalesorderID ) ) ).
   CALL METHOD ('\PROGRAM=ZREUSEBP_R_SALESORDERTP_002===CP\CLASS=LC_SALESORDER_EVENT')=>raise_event_pdf_created PARAMETER-TABLE ptab.

   DATA(a) = 1.

  ENDMETHOD.
ENDCLASS.
