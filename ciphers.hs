-- Lesson 15. Capstone: Secret messages!

-- 
-- RotN Ciphers
--

-- Generic rotN encoder for any alphabet
rotN :: (Bounded a, Enum a) => Int -> a -> a
rotN alphabetSize c = toEnum rotation
    where   halfAlphabet = alphabetSize `div` 2
            offset = fromEnum c + halfAlphabet
            rotation = offset `mod` alphabetSize

-- Generic rotN decoder for any alphabet - handles asymmetry with alphabets of odd size
rotNDecoder :: (Bounded a, Enum a) => Int -> a -> a
rotNDecoder n c = toEnum rotation
    where   halfN = n `div` 2
            offset =    if even n       -- check if alphabet size is even
                        then fromEnum c + halfN
                        else 1 + fromEnum c + halfN
            rotation = offset `mod` n


-- Rotating strings
rotEncoder :: String -> String
rotEncoder text = map rotChar text
    where   alphaSize = 1 + fromEnum (maxBound :: Char)
            rotChar = rotN alphaSize

rotDecoder :: String -> String
rotDecoder text = map rotCharDecoder text
    where   alphaSize = 1 + fromEnum (maxBound :: Char)
            rotCharDecoder = rotNDecoder alphaSize

-- Three Letter Alphabet
data ThreeLetterAlphabet = Alpha | Beta | Kappa deriving (Show, Enum, Bounded)

threeLetterEncoder :: [ThreeLetterAlphabet] -> [ThreeLetterAlphabet]
threeLetterEncoder vals = map rot3l vals
    where   alphaSize = 1 + fromEnum (maxBound :: ThreeLetterAlphabet)
            rot3l = rotN alphaSize

threeLetterDecoder :: [ThreeLetterAlphabet] -> [ThreeLetterAlphabet]
threeLetterDecoder vals = map rot3lDecoder vals
    where   alphaSize = 1 + fromEnum (maxBound :: ThreeLetterAlphabet)
            rot3lDecoder = rotNDecoder alphaSize

-- Four Letter Alphabet
data FourLetterAlphabet = L1 | L2 | L3 | L4 deriving (Show, Enum, Bounded)

fourLetterEncoder :: [FourLetterAlphabet] -> [FourLetterAlphabet]
fourLetterEncoder vals = map rot4l vals
    where   alphaSize = 1 + fromEnum (maxBound :: FourLetterAlphabet)
            rot4l = rotN alphaSize

fourLetterDecoder :: [FourLetterAlphabet] -> [FourLetterAlphabet]
fourLetterDecoder vals = map rot4lDecoder vals
    where   alphaSize = 1 + fromEnum (maxBound :: FourLetterAlphabet)
            rot4lDecoder = rotNDecoder alphaSize

--
-- XOR
--

-- xor functions

xorBool :: Bool -> Bool -> Bool
xorBool value1 value2 = (value1 || value2) && (not (value1 && value2))

xorPair :: (Bool, Bool) -> Bool
xorPair (v1, v2) = xorBool v1 v2

xor :: [Bool] -> [Bool] -> [Bool]
xor list1 list2 = map xorPair (zip list1 list2)

-- Convert text into Bits

type Bits = [Bool]

-- Helper function that converts an int into bits using modulo 2 
intToBits' :: Int -> Bits
intToBits' 0 = [False]
intToBits' 1 = [True]
intToBits' n =  if remainder == 0
                then False : intToBits' nextVal
                else True : intToBits' nextVal
    where
        remainder = n `mod` 2
        nextVal = n `div` 2

maxBits :: Int
maxBits = length (intToBits' maxBound)

-- Main function to convert an int into bits - uses inToBits' but reverses the result and pads
-- with leading Falses so each int is representing by a uniform number of bits
intToBits :: Int -> Bits
intToBits n = leadingFalses ++ reversedBits
    where
        reversedBits = reverse (intToBits' n)
        missingBits = maxBits - (length reversedBits)
        leadingFalses = take missingBits (cycle [False])

charToBits :: Char -> Bits
charToBits char = intToBits (fromEnum char)

-- Convert bits to ints
bitsToInt :: Bits -> Int
bitsToInt bits = sum (map (\x -> 2^ snd x) trueLocations)
    where   size = length bits
            indices = [size-1, size-2 .. 0]
            trueLocations = filter (\x -> fst x == True) (zip bits indices)

bitsToChar :: Bits -> Char
bitsToChar bits = toEnum (bitsToInt bits)

-- One Time Pad

applyOTP' :: String -> String -> [Bits]
applyOTP' pad plaintext = map (\pair -> (fst pair) `xor` (snd pair))
                              (zip padBits plaintextBits)
    where
        padBits = map charToBits pad
        plaintextBits = map charToBits plaintext

applyOTP :: String -> String -> String
applyOTP pad plaintext = map bitsToChar (applyOTP' pad plaintext)

-- Stream Cipher

-- Linear Congruential Pseudo-Random Number Generator
-- a is the multiplier, b the increment, and maxNumber the modulus in the recurrence
-- equation that defines the prng
prng :: Int -> Int -> Int -> Int -> Int
prng a b maxNumber seed = (a*seed + b) `mod` maxNumber

-- Use PRNG to generate random bits
-- genRandomeBits' is a helper function that generates a list of Ints
genRandomBits' :: Int -> Int -> Int -> Int -> [Int]
genRandomBits' a b n seed
    | n == 0 = []
    | otherwise = seed : genRandomBits' a b (n - 1) s
    where s = prng a b n seed

-- genRandomeBits is the main generator function that creates list of bits
-- from a list of ints generated by genRandomBits'
genRandomBits :: Int -> Int -> Int -> Int -> [Bits]
genRandomBits a b n seed = map intToBits (genRandomBits' a b n seed)

-- streamCipher' is a helper function that encodes/decodes text into a list of bits
streamCipher' :: String -> Int -> Int -> Int -> Int -> [Bits]
streamCipher' plaintext a b n seed  = map (\pair -> (fst pair) `xor` (snd pair))
                                        (zip streamBits plaintextBits)
    where
        plaintextBits = map charToBits plaintext
        streamBits = genRandomBits a b n seed

-- streamCipher encodes/decodes text using streamCipger'
streamCipher :: String -> Int -> Int -> Int -> Int -> String
streamCipher plaintext a b seed = map bitsToChar (streamCipher' plaintext a b n seed)


-- Cipher class
class Cipher a where
    encode :: a -> String -> String
    decode :: a -> String -> String

-- Create a Cipher instance for the Rot cipher
data Rot = Rot
instance Cipher Rot where
    encode Rot text = rotEncoder text
    decode Rot text = rotDecoder text

-- Create a Cipher instance for the One Time Pad
data OneTimePad = OTP String
instance Cipher OneTimePad  where
    encode (OTP pad) text = applyOTP pad text
    decode (OTP pad) text = applyOTP pad text

-- Create limitless pad using lazy evaluation (but not random!)
myOTP :: OneTimePad
myOTP = OTP (cycle [minBound .. maxBound])

-- Create a Cipher instance for the Steam Cipher
data StreamCipher = SC Int Int Int Int
instance Cipher StreamCipher where
    encode (SC a b n seed) text = streamCipher text a b n seed
    decode (SC a b n seed) text = streamCipher text a b n seed

-- Create an example PRNG stream cipher
mySC = SC 1337 7 100 1234

-- and use it: encode mySC "This is some text"