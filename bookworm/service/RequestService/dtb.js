require('dotenv').config(); // Load biến môi trường
const mongoose = require('mongoose');

const connectRequestDB = async () => {
    try {
        const uri = process.env.MONGO_URI; // Lấy URI từ .env
        if (!uri) {
            throw new Error("Chưa cấu hình MONGO_URI trong file .env");
        }

        await mongoose.connect(uri);
        console.log("✅ Kết nối RequestService MongoDB thành công!");
    } catch (error) {
        console.error("❌ Lỗi kết nối MongoDB:", error.message);
        process.exit(1);
    }
};

module.exports = connectRequestDB;
