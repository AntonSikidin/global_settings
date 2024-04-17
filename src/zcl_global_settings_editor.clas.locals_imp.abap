*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
    CONSTANTS:
      BEGIN OF mc_func,
        save    TYPE sy-ucomm VALUE 'DBSAVE',
        undo    TYPE sy-ucomm VALUE 'UNDO',
        redo    TYPE sy-ucomm VALUE 'REDO',
        clear   TYPE sy-ucomm VALUE 'CLEAR',
        history TYPE sy-ucomm VALUE 'HIST',
        massins TYPE sy-ucomm VALUE 'MASSINS',
        insert  TYPE sy-ucomm VALUE 'INS',
        modify  TYPE sy-ucomm VALUE 'MOD',
        delete  TYPE sy-ucomm VALUE 'DEL',
        import  TYPE sy-ucomm VALUE 'IMPORT',
        export  TYPE sy-ucomm VALUE 'EXPORT',
      END OF mc_func,
      BEGIN OF mc_status,
        main_prog TYPE sy-repid VALUE 'ZPR_GLOBAL_SETTINGS',
        main_stat TYPE sy-pfkey VALUE 'ZMAIN',
        hist_prog TYPE sy-repid VALUE 'ZPR_GLOBAL_SETTINGS',
        hist_stat TYPE sy-pfkey VALUE 'SALV_HIST',
      END OF mc_status.
