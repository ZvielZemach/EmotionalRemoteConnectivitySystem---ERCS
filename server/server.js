const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const ytdl = require('ytdl-core');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config(); // עבור קריאת משתנים מקובץ .env

const app = express();

// קריאה לפורט מהמשתנים הסביבתיים, אם לא מוגדר ברירת המחדל היא 3000
const port = process.env.PORT || 80;

// Configure multer for handling file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir);
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        cb(null, uuidv4() + path.extname(file.originalname));
    },
});

const upload = multer({ storage });

// Middleware for parsing JSON bodies
app.use(express.json());

// Route for downloading a song from YouTube
app.post('/download-youtube', async (req, res) => {
    const { youtubeUrl } = req.body;
    console.log('Downloading from YouTube:', youtubeUrl);

    if (!ytdl.validateURL(youtubeUrl)) {
        return res.status(400).json({ error: 'Invalid YouTube URL' });
    }

    try {
        const info = await ytdl.getInfo(youtubeUrl);
        const videoTitle = info.videoDetails.title.replace(/[^a-zA-Z0-9]/g, '_'); // Sanitize the title
        const audioFile = path.join(__dirname, 'downloads', `${videoTitle}.mp3`);

        if (!fs.existsSync(path.dirname(audioFile))) {
            fs.mkdirSync(path.dirname(audioFile), { recursive: true });
        }

        ytdl(youtubeUrl, { filter: 'audioonly' })
            .pipe(fs.createWriteStream(audioFile))
            .on('finish', () => {
                res.json({ message: 'Song downloaded successfully', filePath: audioFile });
            })
            .on('error', (error) => {
                console.error('Error downloading the YouTube video:', error);
                res.status(500).json({ error: 'Failed to download the song from YouTube' });
            });
    } catch (error) {
        console.error('Error processing YouTube URL:', error);
        res.status(500).json({ error: 'Error downloading the YouTube video' });
    }
});

// Route for sending files and messages to ESP32
app.post('/send-to-esp32', upload.single('file'), (req, res) => {
    const { file, body } = req;
    const { message } = body;

    let filePath = null;

    // If a file is uploaded, set the file path
    if (file) {
        filePath = file.path; // The file's path (image or audio)
    }

    // If there's a message, you can include it as well
    console.log("Message:", message);

    // Logic to send to ESP32
    console.log(`Sending file: ${filePath}, Message: ${message}`);

    // Here, you should send the data to your ESP32, perhaps through a request to the ESP32 or another method
    // For now, we just send a success response
    res.json({
        message: `File and message sent to ESP32: ${filePath || 'No file'} - ${message || 'No message'}`
    });
});

// Start the server on all network interfaces
app.listen(port, '0.0.0.0', () => {
    console.log(`Server is running on http://0.0.0.0:${port}`);
});
