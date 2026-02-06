import * as cmsService from '../services/cms.service.js';
import AppError from '../errors/AppError.js';

/**
 * @desc    Get CMS page by slug (Admin)
 * @route   GET /api/v1/admin/cms/:slug
 * @access  Private (Admin)
 */
export const getCMSBySlug = async (req, res, next) => {
  try {
    const { slug } = req.params;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    const cms = await cmsService.getCMSBySlug(slug, true);

    if (!cms) {
      return res.status(404).json({
        success: false,
        message: 'CMS page not found'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        slug: cms.slug,
        title: cms.title,
        content: cms.content,
        target: cms.target,
        status: cms.status,
        published_content: cms.published_content,
        published_at: cms.published_at,
        version_history: cms.version_history || [],
        created_date: cms.created_date,
        updated_date: cms.updated_date,
        created_by: cms.created_by,
        updated_by: cms.updated_by
      }
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Get all CMS pages (Admin)
 * @route   GET /api/v1/admin/cms
 * @access  Private (Admin)
 */
export const getAllCMS = async (req, res, next) => {
  try {
    const filters = {
      status: req.query.status,
      target: req.query.target,
      sort: req.query.sort || '-updated_date'
    };

    const cmsPages = await cmsService.getAllCMS(filters);

    res.status(200).json({
      success: true,
      data: cmsPages.map(page => ({
        slug: page.slug,
        title: page.title,
        content: page.content,
        target: page.target,
        status: page.status,
        published_content: page.published_content,
        published_at: page.published_at,
        created_date: page.created_date,
        updated_date: page.updated_date,
        created_by: page.created_by,
        updated_by: page.updated_by
      }))
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Create or update CMS page (Admin)
 * @route   PUT /api/v1/admin/cms/:slug
 * @access  Private (Admin)
 */
export const upsertCMS = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const { title, content, target, status } = req.body;
    const adminId = req.admin?.id || null;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const cms = await cmsService.upsertCMS(
      slug,
      { title, content, target, status },
      adminId
    );

    res.status(200).json({
      success: true,
      message: cms.status === 'published' 
        ? 'CMS page published successfully' 
        : 'CMS page saved as draft successfully',
      data: {
        slug: cms.slug,
        title: cms.title,
        content: cms.content,
        target: cms.target,
        status: cms.status,
        published_content: cms.published_content,
        published_at: cms.published_at,
        updated_date: cms.updated_date
      }
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Publish CMS page (Admin)
 * @route   POST /api/v1/admin/cms/:slug/publish
 * @access  Private (Admin)
 */
export const publishCMS = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const adminId = req.admin?.id || null;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    const cms = await cmsService.publishCMS(slug, adminId);

    res.status(200).json({
      success: true,
      message: 'CMS page published successfully',
      data: {
        slug: cms.slug,
        title: cms.title,
        content: cms.content,
        target: cms.target,
        status: cms.status,
        published_content: cms.published_content,
        published_at: cms.published_at,
        updated_date: cms.updated_date
      }
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Rollback CMS page to previous version (Admin)
 * @route   POST /api/v1/admin/cms/:slug/rollback
 * @access  Private (Admin)
 */
export const rollbackCMS = async (req, res, next) => {
  try {
    const { slug } = req.params;
    const { version_index } = req.body;
    const adminId = req.admin?.id || null;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    if (version_index === undefined || version_index === null) {
      return res.status(400).json({
        success: false,
        message: 'Version index is required'
      });
    }

    const cms = await cmsService.rollbackCMS(slug, version_index, adminId);

    res.status(200).json({
      success: true,
      message: 'CMS page rolled back successfully',
      data: {
        slug: cms.slug,
        title: cms.title,
        content: cms.content,
        target: cms.target,
        status: cms.status,
        updated_date: cms.updated_date
      }
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Delete CMS page (Admin)
 * @route   DELETE /api/v1/admin/cms/:slug
 * @access  Private (Admin)
 */
export const deleteCMS = async (req, res, next) => {
  try {
    const { slug } = req.params;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    await cmsService.deleteCMS(slug);

    res.status(200).json({
      success: true,
      message: 'CMS page deleted successfully'
    });
  } catch (error) {
    if (error instanceof AppError) {
      return res.status(error.statusCode).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};

/**
 * @desc    Get published CMS page by slug (Public)
 * @route   GET /api/v1/cms/:slug
 * @access  Public
 */
export const getPublishedCMSBySlug = async (req, res, next) => {
  try {
    const { slug } = req.params;

    if (!slug) {
      return res.status(400).json({
        success: false,
        message: 'Slug is required'
      });
    }

    const cms = await cmsService.getPublishedCMSBySlug(slug);

    res.status(200).json({
      success: true,
      data: cms
    });
  } catch (error) {
    if (error instanceof AppError && error.statusCode === 404) {
      return res.status(404).json({
        success: false,
        message: error.message
      });
    }
    next(error);
  }
};
