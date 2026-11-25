{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_my_haskell_project (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "my_haskell_project"
version :: Version
version = Version [0,1,0,0] []

synopsis :: String
synopsis = "\1086\1073\1088\1072\1097\1077\1085\1080\1077 \1082 \1073\1072\1079\1077 \1076\1072\1085\1085\1099\1093 \1076\1083\1103 \1089\1086\1079\1076\1072\1085\1080\1103 \1101\1084\1091\1083\1103\1094\1080\1080 \1073\1086\1083\1100\1096\1080\1093 \1073\1072\1079 \1076\1072\1085\1085\1099\1093"
copyright :: String
copyright = ""
homepage :: String
homepage = ""
