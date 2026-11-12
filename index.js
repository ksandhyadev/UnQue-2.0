import express from "express";
import bodyParser from "body-parser";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import helmet from "helmet";
import morgan from "morgan";
import { notFound, errorMiddleware } from "./middleware/error.js";
import userRoutes from "./routes/user.js";
import professorRoutes from "./routes/proff.js";
import generalRoutes from "./routes/general.js";

dotenv.config();

const app = express();

app.use(express.json());
app.use(helmet());
app.use(helmet.crossOriginResourcePolicy({ policy: "cross-origin" }));
app.use(morgan("common"));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cors());

app.use("/users", userRoutes);
app.use("/professor", professorRoutes);
app.use("/general", generalRoutes);
app.use(notFound);
app.use(errorMiddleware);

const PORT = process.env.PORT || 5001;
const connectOptions = {};

if (process.env.DOCDB_TLS === "true") {
  connectOptions.tls = true;

  if (process.env.DOCDB_TLS_CA_FILE) {
    connectOptions.tlsCAFile = process.env.DOCDB_TLS_CA_FILE;
  }
}

if (!process.env.MONGO_URL) {
  console.error("MONGO_URL is required.");
  process.exit(1);
}

mongoose
  .connect(process.env.MONGO_URL, connectOptions)
  .then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Server listening on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("Database connection failed:", error.message);
    process.exit(1);
  });