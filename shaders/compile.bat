@echo off
cd /d "%~dp0"
ShaderCompiler.exe -little "anim_submerge" "anim_submerge.vs" "anim_submerge.ps" "anim_submerge.ksh" -oglsl
