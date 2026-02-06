import CMS from '../models/CMS.model.js';
import AppError from '../errors/AppError.js';
import { sanitizeHTML } from '../utils/htmlSanitizer.js';

/**
 * Get CMS page by slug (Admin - returns draft or published)
 */
export const getCMSBySlug = async (slug, includeDraft = true) => {
  try {
    const query = { slug: slug.toLowerCase() };
    
    if (!includeDraft) {
      query.status = 'published';
    }

    const cms = await CMS.findOne(query)
      .populate('created_by', 'name email')
      .populate('updated_by', 'name email')
      .lean();

    if (!cms) {
      return null;
    }

    return cms;
  } catch (error) {
    throw new AppError('Failed to fetch CMS page', 500);
  }
};

/**
 * Get published CMS page by slug (Public API)
 */
export const getPublishedCMSBySlug = async (slug) => {
  try {
    const cms = await CMS.findOne({
      slug: slug.toLowerCase(),
      status: 'published'
    }).lean();

    if (!cms) {
      throw new AppError('CMS page not found or not published', 404);
    }

    return {
      slug: cms.slug,
      title: cms.title,
      content: cms.published_content || cms.content,
      target: cms.target,
      updatedAt: cms.updated_date
    };
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to fetch CMS page', 500);
  }
};

/**
 * Get all CMS pages (Admin)
 */
export const getAllCMS = async (filters = {}) => {
  try {
    const { status, target, sort = '-updated_date' } = filters;

    const query = {};
    if (status) query.status = status;
    if (target) query.target = target;

    const cmsPages = await CMS.find(query)
      .sort(sort)
      .populate('created_by', 'name email')
      .populate('updated_by', 'name email')
      .lean();

    return cmsPages;
  } catch (error) {
    throw new AppError('Failed to fetch CMS pages', 500);
  }
};

/**
 * Create or update CMS page
 */
export const upsertCMS = async (slug, cmsData, adminId = null) => {
  try {
    const {
      title,
      content,
      target,
      status = 'draft'
    } = cmsData;

    if (!title || !title.trim()) {
      throw new AppError('Title is required', 400);
    }

    if (!content || typeof content !== 'string') {
      throw new AppError('Content is required', 400);
    }

    // Sanitize HTML content
    const sanitizedContent = sanitizeHTML(content);

    // Check if content has actual text (not just empty HTML tags)
    const textContent = sanitizedContent.replace(/<[^>]*>/g, '').trim();
    if (!textContent && !sanitizedContent.includes('<img')) {
      throw new AppError('Content cannot be empty. Please add some text or images.', 400);
    }

    if (!['customer', 'washer', 'both'].includes(target)) {
      throw new AppError('Invalid target. Must be customer, washer, or both', 400);
    }

    if (!['draft', 'published'].includes(status)) {
      throw new AppError('Invalid status. Must be draft or published', 400);
    }

    const normalizedSlug = slug.toLowerCase();

    // Find existing CMS page
    let cms = await CMS.findOne({ slug: normalizedSlug });

    const updateData = {
      title,
      content: sanitizedContent,
      target,
      updated_by: adminId
    };

    if (status === 'published') {
      updateData.status = 'published';
      updateData.published_content = sanitizedContent;
      updateData.published_at = new Date();
    } else {
      updateData.status = 'draft';
    }

    if (cms) {
      // Update existing CMS page
      // Save current version to history before updating
      if (cms.content && cms.version_history) {
        cms.version_history.push({
          content: cms.content,
          status: cms.status,
          updated_by: cms.updated_by,
          updated_at: cms.updated_date
        });
      }

      // Update fields
      Object.assign(cms, updateData);
      await cms.save();

      return cms;
    } else {
      // Create new CMS page
      updateData.slug = normalizedSlug;
      updateData.created_by = adminId;

      cms = await CMS.create(updateData);
      return cms;
    }
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    if (error.code === 11000) {
      throw new AppError('CMS page with this slug already exists', 400);
    }
    throw new AppError('Failed to save CMS page', 500);
  }
};

/**
 * Publish CMS page (moves draft to published)
 */
export const publishCMS = async (slug, adminId = null) => {
  try {
    const normalizedSlug = slug.toLowerCase();
    const cms = await CMS.findOne({ slug: normalizedSlug });

    if (!cms) {
      throw new AppError('CMS page not found. Please save as draft first.', 404);
    }

    if (cms.status === 'published') {
      // Allow republishing - update the published content
      // Save current published version to history
      if (cms.published_content && cms.version_history) {
        cms.version_history.push({
          content: cms.published_content,
          status: 'published',
          updated_by: cms.updated_by,
          updated_at: cms.published_at || cms.updated_date
        });
      }
    } else {
      // Save current draft to history before publishing
      if (cms.content && cms.version_history) {
        cms.version_history.push({
          content: cms.content,
          status: 'draft',
          updated_by: cms.updated_by,
          updated_at: cms.updated_date
        });
      }
    }

    // Publish the current draft content
    cms.status = 'published';
    cms.published_content = cms.content; // Use current content (draft)
    cms.published_at = new Date();
    cms.updated_by = adminId;
    await cms.save();

    return cms;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to publish CMS page', 500);
  }
};

/**
 * Rollback to a previous version
 */
export const rollbackCMS = async (slug, versionIndex, adminId = null) => {
  try {
    const cms = await CMS.findOne({ slug: slug.toLowerCase() });

    if (!cms) {
      throw new AppError('CMS page not found', 404);
    }

    if (!cms.version_history || versionIndex < 0 || versionIndex >= cms.version_history.length) {
      throw new AppError('Invalid version index', 400);
    }

    const version = cms.version_history[versionIndex];

    // Save current version to history before rollback
    if (cms.content && cms.version_history) {
      cms.version_history.push({
        content: cms.content,
        status: cms.status,
        updated_by: cms.updated_by,
        updated_at: cms.updated_date
      });
    }

    // Rollback to selected version
    cms.content = version.content;
    cms.status = version.status;
    cms.updated_by = adminId;
    await cms.save();

    return cms;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to rollback CMS page', 500);
  }
};

/**
 * Delete CMS page
 */
export const deleteCMS = async (slug) => {
  try {
    const cms = await CMS.findOneAndDelete({ slug: slug.toLowerCase() });

    if (!cms) {
      throw new AppError('CMS page not found', 404);
    }

    return cms;
  } catch (error) {
    if (error instanceof AppError) {
      throw error;
    }
    throw new AppError('Failed to delete CMS page', 500);
  }
};
