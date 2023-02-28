{-# LANGUAGE OverloadedStrings #-}

module Kafka2kafka.Internal.UtilSpec (spec) where

import Test.Hspec
-- import Test.QuickCheck
import qualified Data.Map as Map
import Kafka2kafka.Internal.Util
import Kafka2kafka.Entity.Config


spec :: Spec
spec = do

    describe "mapConfigCerts" $ do
        it "should return ssl properties map" $ do
            mapConfigCerts (ConfigCerts {
                                        protocol = "protocol", 
                                        caLocation = "caLocation", 
                                        certificateLocation = "certificateLocation", 
                                        keyLocation = "keyLocation" 
                            }) 
                            `shouldBe` 
                                Map.fromList [("security.protocol", "protocol"),
                                              ("ssl.ca.location", "caLocation"),
                                              ("ssl.certificate.location", "certificateLocation"),
                                              ("ssl.key.location", "keyLocation")]