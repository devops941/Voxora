import { randomUUID } from 'crypto';
import { AppError } from '../../types';
import { FinalAssessment } from '../final_assessment/final_assessment.model';
import { Certificate } from './certificate.model';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const PDFDocument = require('pdfkit');

interface CertificateData {
  fullName: string;
  level: string;
  score: number;
  percentage: number;
  completionDate: Date;
  certificateId: string;
  isTestMode: boolean;
}

export class CertificateService {
  async generateCertificate(
    userId: string,
    assessmentId: string,
    fullName: string,
    email: string
  ) {
    const assessment = await FinalAssessment.findOne({ _id: assessmentId, userId });
    if (!assessment) throw new AppError('Assessment not found', 404);
    if (assessment.status !== 'pass') {
      throw new AppError('You must pass the assessment to generate a certificate', 400);
    }

    // Return existing certificate if already generated
    const existing = await Certificate.findOne({ finalAssessmentId: assessmentId });
    if (existing) {
      return {
        certificateId: existing.certificateId,
        level: existing.level,
        score: existing.score,
        percentage: existing.percentage,
        isTestMode: existing.isTestMode,
      };
    }

    const certificateId = randomUUID();
    const completionDate = assessment.submittedAt || new Date();

    const pdfBuffer = await this.createCertificatePDF({
      fullName,
      level: assessment.level,
      score: assessment.score,
      percentage: assessment.score,
      completionDate,
      certificateId,
      isTestMode: assessment.isTestMode,
    });

    await Certificate.create({
      userId,
      finalAssessmentId: assessmentId,
      certificateId,
      fullName,
      email,
      level: assessment.level,
      score: assessment.score,
      percentage: assessment.score,
      completionDate,
      isTestMode: assessment.isTestMode,
      pdfBuffer,
    });

    return {
      certificateId,
      level: assessment.level,
      score: assessment.score,
      percentage: assessment.score,
      isTestMode: assessment.isTestMode,
    };
  }

  async downloadCertificate(
    certificateId: string,
    userId: string
  ): Promise<{ buffer: Buffer; filename: string; isTestMode: boolean }> {
    const cert = await Certificate.findOne({ certificateId, userId });
    if (!cert) throw new AppError('Certificate not found', 404);

    let buffer = cert.pdfBuffer;
    if (!buffer) {
      buffer = await this.createCertificatePDF({
        fullName: cert.fullName,
        level: cert.level,
        score: cert.score,
        percentage: cert.percentage,
        completionDate: cert.completionDate,
        certificateId: cert.certificateId,
        isTestMode: cert.isTestMode,
      });
      cert.pdfBuffer = buffer;
      await cert.save();
    }

    const prefix = cert.isTestMode ? 'TEST_' : '';
    return {
      buffer,
      filename: `${prefix}Voxora_Certificate_${cert.level}.pdf`,
      isTestMode: cert.isTestMode,
    };
  }

  private createCertificatePDF(data: CertificateData): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      const chunks: Buffer[] = [];
      const doc = new PDFDocument({ size: 'A4', layout: 'landscape', margin: 0 });

      doc.on('data', (chunk: Buffer) => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      const W = 841.89;
      const H = 595.28;

      // Background
      doc.rect(0, 0, W, H).fill('#1a3a6b');

      // Outer border
      doc.rect(16, 16, W - 32, H - 32).lineWidth(2.5).strokeColor('#ffffff').stroke();
      // Inner border
      doc.rect(24, 24, W - 48, H - 48).lineWidth(0.8).strokeColor('#4a7ab5').stroke();

      // Corner accents
      const corners = [[30, 30], [W - 30, 30], [30, H - 30], [W - 30, H - 30]] as const;
      corners.forEach(([cx, cy]) => {
        doc.circle(cx, cy, 6).fill('#FFD700');
      });

      // App name
      doc.fillColor('#ffffff').fontSize(40).font('Helvetica-Bold')
        .text('VOXORA', 0, 52, { align: 'center', width: W });

      // Tagline
      doc.fillColor('#90b8e0').fontSize(13).font('Helvetica')
        .text('AI Spoken English Coach', 0, 98, { align: 'center', width: W });

      // Top separator
      doc.moveTo(100, 122).lineTo(W - 100, 122).lineWidth(1).strokeColor('#4a7ab5').stroke();

      // "Certificate of Completion"
      doc.fillColor('#ffffff').fontSize(27).font('Helvetica-Bold')
        .text('Certificate of Completion', 0, 136, { align: 'center', width: W });

      // "This certifies that"
      doc.fillColor('#b0cce8').fontSize(13).font('Helvetica')
        .text('This certifies that', 0, 178, { align: 'center', width: W });

      // Recipient name
      doc.fillColor('#FFD700').fontSize(32).font('Helvetica-Bold')
        .text(data.fullName, 0, 200, { align: 'center', width: W });

      // Completion statement
      doc.fillColor('#b0cce8').fontSize(13).font('Helvetica')
        .text(
          `has successfully completed the ${data.level} Level English Speaking Course`,
          0, 248, { align: 'center', width: W }
        );

      // Score
      doc.fillColor('#ffffff').fontSize(15).font('Helvetica-Bold')
        .text(
          `Final Assessment Score: ${data.score}/100 (${data.percentage.toFixed(0)}%)`,
          0, 278, { align: 'center', width: W }
        );

      // Date
      const dateStr = new Date(data.completionDate).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
      doc.fillColor('#90b8e0').fontSize(12).font('Helvetica')
        .text(`Completed on: ${dateStr}`, 0, 308, { align: 'center', width: W });

      // Certificate ID
      doc.fillColor('#4a6a8a').fontSize(9).font('Helvetica')
        .text(`Certificate ID: ${data.certificateId}`, 0, 336, { align: 'center', width: W });

      // Footer separator
      doc.moveTo(100, 360).lineTo(W - 100, 360).lineWidth(0.5).strokeColor('#4a7ab5').stroke();

      // Footer
      doc.fillColor('#506070').fontSize(10).font('Helvetica')
        .text(
          'www.voxora.app  •  AI Spoken English Coach  •  Powered by Kaizen Infinities',
          0, 372, { align: 'center', width: W }
        );

      // TEST WATERMARK — clearly marks test certificates as invalid
      if (data.isTestMode) {
        doc.save();
        doc.translate(W / 2, H / 2);
        doc.rotate(-45);
        doc
          .fillColor('#ff0000')
          .opacity(0.35)
          .fontSize(52)
          .font('Helvetica-Bold')
          .text('TEST CERTIFICATE – NOT VALID', -300, -34, { lineBreak: false });
        doc.restore();
      }

      doc.end();
    });
  }
}

export const certificateService = new CertificateService();
