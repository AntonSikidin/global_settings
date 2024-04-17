*&---------------------------------------------------------------------*
*& Report  ZPR_GLOBAL_SETTINGS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zpr_global_settings.



PARAMETERS
: p_proj TYPE akb_project_name MATCHCODE OBJECT zsh_global_settings_project OBLIGATORY
.


*----------------------------------------------------------------------*
* START-OF-SELECTION                                                   *
*----------------------------------------------------------------------*
START-OF-SELECTION.
  zcl_global_settings_editor=>main( p_proj ).
  CALL SCREEN 100.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZMAIN'.
  SET TITLEBAR 'TITLEBAR0100'.

  zcl_global_settings_editor=>pbo( ).
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  zcl_global_settings_editor=>pai( ).
ENDMODULE.
