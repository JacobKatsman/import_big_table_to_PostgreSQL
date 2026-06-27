{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Database.PostgreSQL.Simple as PG
import Control.Exception (bracket)
import Data.Int (Int32)
import System.Random
import Control.Monad
import Data.Time.Clock (getCurrentTime, diffUTCTime)
import System.IO (hFlush, stdout)
import qualified Database.PostgreSQL.Simple.Copy as PGCopy
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Lazy as BL
import Data.Functor (void)
import qualified Data.ByteString.Lazy as LBS 
import System.Environment (lookupEnv)
import Data.Maybe (fromMaybe)


{-|
Module      : Main
Description : Импортирование случайно созданной таблицы
Copyright   : (c) Alexey Chikilevsky, 2026
License     : MIT
Maintainer  : call89269081096@gmail.com
Stability   : experimental
Portability : POSIX/Linux

=============================================================================
    PostgreSQL's Import Script 
=============================================================================
     En: High-speed generation of 10^6 records in a PostgreSQL table with a left-skewed normal data distribution.
     This implementation serves as a scalable template for developing production-grade data import pipelines.

     Ru: Очень Быстрое заполнение большой (1 миллион записей) таблицы в posgreSQL
     случайными данными с левосторонним нормальным распределением.
     Может использоваться как паттерн для Ваших импортов.

     Использование(uses):
     $ cabal build --ghc-options="-w"
     $ export $(cat .env | xargs) && cabal run
     Или (or)
     $./app.sh

    ~/my-haskell-project $ ./app.sh
    [##################################################] 100% (1000000/1000000)
    Program execution time: 1.909940535s

=============================================================================
-}

measureTime :: IO a -> IO (a, Double)
measureTime action = do
    start <- getCurrentTime
    result <- action
    end <- getCurrentTime
    let diff = diffUTCTime end start
    return (result, realToFrac diff)

callProcedureRow :: PG.Connection -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> Int32 -> IO ()
callProcedureRow conn a b c d e f = do
        void $ PG.execute conn "CALL insert_tbloom2_row(?, ?, ?, ?, ?, ?)" (a, b, c, d, e, f)

callInsertBatch :: PG.Connection -> [(Int32, Int32, Int32, Int32, Int32, Int32)] -> IO ()
callInsertBatch conn rows = do   
    void $ PG.executeMany conn 
        "INSERT INTO tbloom2 (i1, i2, i3, i4, i5, i6) VALUES (?, ?, ?, ?, ?, ?)" 
        rows        

callInsertBatchFast :: PG.Connection -> [(Int32, Int32, Int32, Int32, Int32, Int32)] -> IO ()
callInsertBatchFast conn rows = do
    void $ PGCopy.copy_ conn "COPY tbloom2 (i1, i2, i3, i4, i5, i6) FROM STDIN WITH DELIMITER '\t'"
    let builder = foldMap rowToBuilder rows
        lazyBs  = BB.toLazyByteString builder
    mapM_ (PGCopy.putCopyData conn) (BL.toChunks lazyBs)
    void $ PGCopy.putCopyEnd conn
  where
    rowToBuilder (a, b, c, d, e, f) =
        BB.int32Dec a <> BB.char8 '\t' <>
        BB.int32Dec b <> BB.char8 '\t' <>
        BB.int32Dec c <> BB.char8 '\t' <>
        BB.int32Dec d <> BB.char8 '\t' <>
        BB.int32Dec e <> BB.char8 '\t' <>
        BB.int32Dec f <> BB.char8 '\n'

gRInRange :: (Random a) => (a, a) -> IO a
gRInRange range = getStdRandom (randomR range)

generateRow :: IO (Int32, Int32, Int32, Int32, Int32, Int32)
generateRow = do
    -- должно что-то делаться...
    raw <- generateLeftSkewed 1 120 
    let a = fromIntegral (round  raw) :: Int32
    rawb <- generateLeftSkewed 1 120
    let b = fromIntegral (round  rawb):: Int32
    rawc <- generateLeftSkewed 1 120
    let c =fromIntegral (round  rawc):: Int32
    rawd <- generateLeftSkewed 1 120
    let d = fromIntegral (round  rawd):: Int32
    rawe <- generateLeftSkewed 1 120
    let e = fromIntegral (round  rawe):: Int32
    rawf <- generateLeftSkewed 1 120
    let f = fromIntegral (round  rawf):: Int32
    return (a, b, c, d, e, f)

-- Генерация стандартного нормального распределения (среднее 0, дисперсия 1)
generateNormal :: IO Double
generateNormal = do
    u1 <- gRInRange (0.0, 1.0)
    u2 <- gRInRange (0.0, 1.0)
    let z = sqrt (-2 * log u1) * cos (2 * pi * u2)
    return z

-- Левостороннее нормальное (скошенное влево)
generateLeftSkewed :: Double -> Double -> IO Double
generateLeftSkewed mean std = do
    z <- generateNormal
    let skewness = -1.0  -- степень скошенности
    let skewed = mean + std * (z - skewness * (z^2 - 1) / 3)
    return skewed

progressBar :: Int -> Int -> Int -> String
progressBar batchNum  batchSize totalRows = 
        let inserted = min (batchNum * batchSize) totalRows
            progress = (fromIntegral inserted / fromIntegral totalRows) * 100
            barLength = 50
            filled = round (progress / 100 * fromIntegral barLength)
            bar = replicate filled '#' ++ replicate (barLength - filled) '-'
            str = "\r[" ++ bar ++ "] " ++ show (round progress :: Int) ++ "% (" ++ show inserted ++ "/" ++ show totalRows ++ ")"
        in
            str
  
insertBatch :: PG.Connection -> Int -> Int -> IO ()
insertBatch conn totalRows batchSize = do
    let batches = (totalRows + batchSize - 1) `div` batchSize
    forM_ [1..batches] $ \batchNum -> do
        let currentBatch = min batchSize (totalRows - (batchNum - 1) * batchSize)
        rows <- replicateM currentBatch generateRow
        
        PG.withTransaction conn $ do
           callInsertBatchFast conn rows
           
        putStr $ progressBar batchNum  batchSize totalRows 
        hFlush stdout

main :: IO ()
main = do
    dbHost <- fromMaybe "localhost" <$> lookupEnv "DB_HOST"
    dbName <- fromMaybe "postgres"  <$> lookupEnv "DB_NAME"
    dbUser <- fromMaybe "postgres"  <$> lookupEnv "DB_USER"
    dbPass <- fromMaybe ""          <$> lookupEnv "DB_PASS"

    let connectInfo = PG.defaultConnectInfo
            { PG.connectHost     = dbHost
            , PG.connectDatabase = dbName
            , PG.connectUser     = dbUser
            , PG.connectPassword = dbPass
            }
      
    bracket (PG.connect connectInfo) PG.close $ \conn -> do
        startTime <- getCurrentTime 
        _ <- PG.execute_ conn "SET client_min_messages = WARNING"
        insertBatch conn 1000000 20000
        end <- getCurrentTime  
        let elapsed = diffUTCTime end startTime
        putStrLn $ "\n Program execution time: " ++ show elapsed
       
