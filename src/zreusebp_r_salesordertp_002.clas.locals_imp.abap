

CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR SalesOrder
        RESULT result,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR SalesOrder RESULT result.

    METHODS createPDF FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~createPDF RESULT result.
    METHODS recalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~recalcTotalPrice.
ENDCLASS.

CLASS lhc_salesorder IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD get_instance_features.
  ENDMETHOD.

  METHOD createPDF.

    TYPES: BEGIN OF ty_longtext,
             msgv1(50),
             msgv2(50),
             msgv3(50),
             msgv4(50),
           END OF ty_longtext.

    DATA: ls_longtext TYPE ty_longtext.

    DATA update TYPE TABLE FOR UPDATE ZREUSER_SalesOrderTP_002\\SalesOrder.
    DATA update_line TYPE STRUCTURE FOR UPDATE ZREUSER_SalesOrderTP_002\\SalesOrder .

*    DATA pdf_lib TYPE REF TO  zreuse_cl_generate_pdf.

    DATA error_message TYPE string.


    "get salesorder(s)
    READ ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
       ENTITY SalesOrder
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(salesorders).

*    pdf_lib  = NEW zreuse_cl_generate_pdf( ).

    LOOP AT salesorders INTO DATA(salesorder).
*      IF pdf_lib->error_message_initialization IS INITIAL.
*        pdf_lib->generate_pdf(
*          EXPORTING
*            iv_value      = CONV #( salesorder-SalesorderID )
*          IMPORTING
*            my_pdf        = DATA(my_pdf)
*            error_message = error_message
*        ).
*      ELSE.
*        error_message = pdf_lib->error_message_initialization.
*      ENDIF.
*      IF error_message IS NOT INITIAL.
*        update_line-Description = error_message.
*      ELSE.
      update_line-Description = 'PDF generation started'.


*        update_line-Attachment = my_pdf.
*        update_line-filename = |file_{ salesorder-SalesorderID }.pdf|.
*        update_line-MimeType = 'application/pdf'.
*      ENDIF.
      update_line-%tky      = salesorder-%tky.
      APPEND update_line TO update.


    ENDLOOP.




    MODIFY ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
    ENTITY SalesOrder
      UPDATE FIELDS (
                      Description
*                      Attachment
**                      FileName
*                      MimeType
                      ) WITH update
    REPORTED reported
    FAILED failed
    MAPPED mapped.


    IF failed IS INITIAL.
      "Read changed data for action result
      READ ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
        ENTITY salesorder
          ALL FIELDS WITH
          CORRESPONDING #( keys )
        RESULT DATA(salesorders2).
      result = VALUE #( FOR salesorder2 IN salesorders2 ( %tky   = salesorder2-%tky
                                                          %param = salesorder2 ) ).


    ENDIF.

  ENDMETHOD.



  METHOD recalcTotalPrice.


    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE ZREUSER_SalesOrderTP_002-TotalAmount,
             AmountExclVat TYPE ZREUSER_SalesOrderTP_002-AmountExclVat,
             amountvat     TYPE ZREUSER_SalesOrderTP_002-AmountVat,
             currency_code TYPE ZREUSER_SalesOrderTP_002-CurrencyCode,
           END OF ty_amount_per_currencycode.

    DATA: amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    " Read all relevant travel instances.
    READ ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
         ENTITY SalesOrder
            FIELDS (  TotalAmount AmountExclVat AmountVat )
            WITH CORRESPONDING #( keys )
         RESULT DATA(salesorders).

*    DELETE salesorders WHERE CurrencyCode IS INITIAL.

    " Read all associated bookings and add them to the total price.
    READ ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
      ENTITY Salesorder BY \_Item
        FIELDS ( AmountExclVat AmountVat  Amount )
      WITH CORRESPONDING #( salesorders )
      LINK DATA(item_links)
      RESULT DATA(items).

    READ ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
      ENTITY salesorder BY \_item
        ALL FIELDS
      WITH  CORRESPONDING #( salesorders )
      RESULT DATA(all_items).


    LOOP AT salesorders ASSIGNING FIELD-SYMBOL(<salesorder>).
      " Set the start for the calculation by adding the booking fee.
*       amounts_per_currencycode = VALUE #( ( amount        = <travel>-bookingfee
*                                             currency_code = <travel>-currencycode ) ).

      LOOP AT all_items INTO DATA(item).
        COLLECT VALUE ty_amount_per_currencycode( amount        = item-Amount
                                                  amountexclvat = item-AmountExclVat
                                                  amountvat     = item-AmountVat
                                                  currency_code = item-currencycode ) INTO amounts_per_currencycode.
      ENDLOOP.

      DELETE amounts_per_currencycode WHERE currency_code IS INITIAL.

      CLEAR <salesorder>-TotalAmount.
      CLEAR <salesorder>-AmountVat.
      CLEAR <salesorder>-AmountExclVat.

      LOOP AT amounts_per_currencycode INTO DATA(amount_per_currencycode).
        " If needed do a Currency Conversion
*        IF amount_per_currencycode-currency_code = <salesorder>-CurrencyCode.
        <salesorder>-TotalAmount += amount_per_currencycode-amount.
        <salesorder>-AmountVat += amount_per_currencycode-amountvat.
        <salesorder>-AmountExclVat += amount_per_currencycode-amountexclvat.

*        ELSE.
*          /dmo/cl_flight_amdp=>convert_currency(
*             EXPORTING
*               iv_amount                   =  amount_per_currencycode-amount
*               iv_currency_code_source     =  amount_per_currencycode-currency_code
*               iv_currency_code_target     =  <travel>-CurrencyCode
*               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
*             IMPORTING
*               ev_amount                   = DATA(total_booking_price_per_curr)
*            ).
*          <travel>-TotalPrice += total_booking_price_per_curr.
*          ASSERT 1 = 2.
*        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " write back the modified total_price of travels
    MODIFY ENTITIES OF ZREUSER_SalesOrderTP_002 IN LOCAL MODE
      ENTITY salesorder
        UPDATE FIELDS ( TotalAmount AmountExclVat AmountVat )
        WITH CORRESPONDING #( salesorders ).


  ENDMETHOD.

ENDCLASS.


CLASS lsc_salesorder_s DEFINITION FINAL INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS:
      save_modified REDEFINITION,
      adjust_numbers REDEFINITION,
      cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_salesorder_s IMPLEMENTATION.

  METHOD save_modified.


    DATA : lt_salesorder_as        TYPE STANDARD TABLE OF zreuse_head_002,
           ls_salesorder_as        TYPE                   zreuse_head_002,
           lt_salesorder_x_control TYPE STANDARD TABLE OF zreuse_head_x_002.



    " Start of default parameter part
    DATA: objectid        TYPE if_chdo_object_tools_rel=>ty_cdobjectv,
          utime           TYPE if_chdo_object_tools_rel=>ty_cduzeit,
          udate           TYPE if_chdo_object_tools_rel=>ty_cddatum,
          username        TYPE if_chdo_object_tools_rel=>ty_cdusername,
          cdoc_upd_object TYPE if_chdo_object_tools_rel=>ty_cdchngindh VALUE 'U'.
    DATA: cdchangenumber  TYPE if_chdo_object_tools_rel=>ty_cdchangenr.
    " End of default parameter part

    " Change Number of Document
    DATA changenumber TYPE if_chdo_object_tools_rel=>ty_cdchangenr.

    "dynamic data
    DATA: o_zreuse_head_002   TYPE zreuse_head_002,
          n_zreuse_head_002   TYPE zreuse_head_002,
          upd_zreuse_head_002 TYPE if_chdo_object_tools_rel=>ty_cdchngindh.


**********************************************************************
* relevent for change document management demo
**********************************************************************


    LOOP AT update-salesorder INTO DATA(salesorder).

      IF salesorder-TotalAmount IS NOT INITIAL  OR
         salesorder-OverallStatus  IS NOT INITIAL
*          OR
*         salesorder-CurrencyCode IS NOT INITIAL
         .
        "fill mandatory values
        "objectid = 'ZREUSE_SO_002'.
        utime = sy-uzeit.
        udate = sy-datum.
        username = sy-uname.

        SELECT SINGLE * FROM zreuse_head_002
        WHERE salesorder_id = @salesorder-SalesorderID
        INTO @o_zreuse_head_002.

        n_zreuse_head_002-salesorder_id  = salesorder-SalesorderID.
        n_zreuse_head_002-total_amount   = salesorder-TotalAmount.
        n_zreuse_head_002-currency_code = salesorder-CurrencyCode.
        n_zreuse_head_002-overall_status = salesorder-OverallStatus.

        upd_zreuse_head_002     =  'U'.

        TRY.
            zcl_zreuse_so_002_chdo=>write(
              EXPORTING
                objectid                = CONV #( salesorder-SalesorderID )
                utime                   = utime
                udate                   = udate
                username                = username
                object_change_indicator = cdoc_upd_object      "Flag: Object inserted, changed or deleted
                o_zreuse_head_002       = o_zreuse_head_002    "Work area with original contents
                n_zreuse_head_002       = n_zreuse_head_002    "Work area with changed contents
                upd_zreuse_head_002     = upd_zreuse_head_002  "Type of Change (create, update, delete)
              IMPORTING
                changenumber            = changenumber
            ).

            DATA(a) = 1.

          CATCH cx_chdo_write_error INTO DATA(exc_write_change_doc).

        ENDTRY.
      ENDIF.
    ENDLOOP.

    "Data must NOT be saved before change doc API is called
    "otherwise no changes are detected.

    IF create-salesorder IS NOT INITIAL.
      lt_salesorder_as = CORRESPONDING #( create-salesorder MAPPING FROM ENTITY ).
      INSERT zreuse_head_002 FROM TABLE @lt_salesorder_as.
    ENDIF.

    IF update IS NOT INITIAL.
      CLEAR lt_salesorder_as.
*      lt_salesorder_as = CORRESPONDING #( update-salesorder MAPPING FROM ENTITY ).
*      lt_salesorder_x_control = CORRESPONDING #( update-salesorder MAPPING FROM ENTITY ).
      UPDATE zreuse_head_002 FROM TABLE @update-salesorder
      INDICATORS SET STRUCTURE %control MAPPING FROM ENTITY. .
    ENDIF.
    IF delete IS NOT INITIAL.
      LOOP AT delete-salesorder INTO DATA(salesorder_delete).
        DELETE FROM zreuse_head_002 WHERE salesorder_id = @salesorder_delete-salesorderID.
        DELETE FROM zreusesal00d_002 WHERE salesorderid = @salesorder_delete-salesorderID.
      ENDLOOP.
    ENDIF.

**********************************************************************
* PDF / Adobe Demo
**********************************************************************


    DATA pdf_salesorders TYPE zcl_generate_pdf_via_bgpf_002=>tt_salesorderid .
    DATA pdf_salesorder TYPE zcl_generate_pdf_via_bgpf_002=>ts_salesorderid .
    DATA bgpf_operation TYPE REF TO zcl_generate_pdf_via_bgpf_002 .

    LOOP AT update-salesorder INTO salesorder WHERE Description = 'PDF generation started'.
      pdf_salesorder-salesorderid = salesorder-SalesorderID.
      APPEND pdf_salesorder TO pdf_salesorders.
    ENDLOOP.

    IF pdf_salesorders IS NOT INITIAL.

      bgpf_operation = NEW zcl_generate_pdf_via_bgpf_002(
             i_salesorders = pdf_salesorders
           ).

      TRY.
          DATA(background_process) = cl_bgmc_process_factory=>get_default(  )->create(  ).
          background_process->set_operation_tx_uncontrolled( bgpf_operation ).
          background_process->set_name( |PDF salesorder {  salesorder-SalesorderID  }| ).
          background_process->save_for_execution(  ).
        CATCH cx_bgmc.
          "handle exception
          ASSERT 1 = 2.
      ENDTRY.

    ENDIF.




  ENDMETHOD.

  METHOD cleanup_finalize.

  ENDMETHOD.

  METHOD adjust_numbers.
    DATA: salesorder_id_max TYPE zreuse_salesorder_id.
    "Root BO entity: Salesorder
    IF mapped-salesorder IS NOT INITIAL.
      TRY.
          "get numbers
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = 'ZREUSES002'
              quantity          = CONV #( lines( mapped-salesorder ) )
            IMPORTING
              number            = DATA(number_range_key)
              returncode        = DATA(number_range_return_code)
              returned_quantity = DATA(number_range_returned_quantity)
          ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          RAISE SHORTDUMP TYPE cx_number_ranges
            EXPORTING
              previous = lx_number_ranges.
      ENDTRY.
      ASSERT number_range_returned_quantity = lines( mapped-salesorder ).
      salesorder_id_max = number_range_key - number_range_returned_quantity.
      LOOP AT mapped-salesorder ASSIGNING FIELD-SYMBOL(<salesorder>).
        salesorder_id_max += 1.
        <salesorder>-salesorderID = salesorder_id_max.
      ENDLOOP.
    ENDIF.

    "Child BO entity: Item
    IF mapped-item IS NOT INITIAL.

      READ ENTITIES OF ZReuseR_SalesOrderTP_002 IN LOCAL MODE
        ENTITY Item BY \_SalesOrder
          FROM VALUE #( FOR item IN mapped-item WHERE ( %tmp-salesorderID IS INITIAL )
                                                            ( %pid = item-%pid
                                                              %key = item-%tmp ) )
        LINK DATA(item_to_salesorder_links).

      LOOP AT mapped-item ASSIGNING FIELD-SYMBOL(<item>).
        <item>-salesorderID =
          COND #( WHEN <item>-%tmp-salesorderID IS INITIAL
                  THEN mapped-salesorder[ %pid = item_to_salesorder_links[ source-%pid = <item>-%pid ]-target-%pid ]-salesorderID
                  ELSE <item>-%tmp-salesorderID ).
      ENDLOOP.

      LOOP AT mapped-item INTO DATA(mapped_item) GROUP BY mapped_item-salesorderID.
        SELECT MAX( item_id ) FROM zreuse_item_002 WHERE salesorder_id = @mapped_item-salesorderID INTO @DATA(max_item_id) .
        LOOP AT GROUP mapped_item ASSIGNING <item>.
          max_item_id += 10.
          <item>-itemID = max_item_id.
        ENDLOOP.
      ENDLOOP.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lc_salesorder_event DEFINITION FINAL.
 PUBLIC SECTION.
   CLASS-METHODS raise_event_pdf_created IMPORTING i_salesorderid type zreuse_salesorder_id_002 .
ENDCLASS.

CLASS lc_salesorder_event IMPLEMENTATION.

  METHOD raise_event_pdf_created.
    RAISE ENTITY EVENT ZREUSER_SalesOrderTP_002~PDFCreated FROM VALUE #( ( salesorderid = i_salesorderid ) ).
  ENDMETHOD.

ENDCLASS.
