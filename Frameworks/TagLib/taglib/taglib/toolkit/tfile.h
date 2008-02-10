/***************************************************************************
    copyright            : (C) 2002, 2003 by Scott Wheeler
    email                : wheeler@kde.org
 ***************************************************************************/

/***************************************************************************
 *   This library is free software; you can redistribute it and/or modify  *
 *   it  under the terms of the GNU Lesser General Public License version  *
 *   2.1 as published by the Free Software Foundation.                     *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful, but   *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  *
 *   USA                                                                   *
 ***************************************************************************/

#ifndef TAGLIB_FILE_H
#define TAGLIB_FILE_H

#include "taglib_export.h"
#include "taglib.h"
#include "tbytevector.h"
#include "tfileio.h"

namespace TagLib {

  class String;
  class Tag;
  class AudioProperties;

  //! A file class with some useful methods for tag manipulation

  /*!
   * This class is a basic file class with some methods that are particularly
   * useful for tag editors.  It has methods to take advantage of
   * ByteVector and a binary search method for finding patterns in a file.
   */

  class TAGLIB_EXPORT File : public TagLib::FileIO
  {
  public:
    
  //! A class for pluggable file I/O type resolution.

  /*!
   * This class is used to extend TagLib's very basic file name based file I/O
   * type resolution.
   *
   * This can be accomplished with:
   *
   * \code
   *
   * class MyFileIOTypeResolver : FileIOTypeResolver
   * {
   *   TagLib::FileIO *createFileIO(const char *fileName)
   *   {
   *     if(someCheckForAnHTTPFile(fileName))
   *       return new MyHTTPFileIO(fileName);
   *     return 0;
   *   }
   * }
   *
   * File::addFileIOTypeResolver(new MyFileIOTypeResolver);
   *
   * \endcode
   *
   * Naturally a less contrived example would be slightly more complex.  This
   * can be used to add new file I/O types to TagLib.
   */

    class FileIOTypeResolver
    {
    public:
      /*!
       * This method must be overriden to provide an additional file I/O type
       * resolver.  If the resolver is able to determine the file I/O type it
       * should return a valid File I/O object; if not it should return 0.
       *
       * \note The created file I/O is then owned by the File and should not be
       * deleted.  Deletion will happen automatically when the File passes out
       * of scope.
       */
      virtual FileIO *createFileIO(const char *fileName) const = 0;
    };

    /*!
     * Destroys this File instance.
     */
    virtual ~File();

    /*!
     * Opens the \a file.  \a file should be a be a C-string in the local file
     * system encoding.
     *
     * \note Constructor is protected since this class should only be
     * instantiated through subclasses.
     */
    void open(const char *file);

    /*!
     * Returns the file name in the local file system encoding.
     */
    const char *name() const;

    /*!
     * Returns the maximum number of bytes to scan when scanning for frames or
     * tags.
     */
    long getMaxScanBytes();

    /*!
     * Sets the maximum number of bytes to scan when scanning for frames or
     * tags to \a maxScanBytes.
     */
    void setMaxScanBytes(long maxScanBytes);

    /*!
     * Returns a pointer to this file's tag.  This should be reimplemented in
     * the concrete subclasses.
     */
    virtual Tag *tag() const = 0;

    /*!
     * Returns a pointer to this file's audio properties.  This should be
     * reimplemented in the concrete subclasses.  If no audio properties were
     * read then this will return a null pointer.
     */
    virtual AudioProperties *audioProperties() const = 0;

    /*!
     * Save the file and its associated tags.  This should be reimplemented in
     * the concrete subclasses.  Returns true if the save succeeds.
     *
     * \warning On UNIX multiple processes are able to write to the same file at
     * the same time.  This can result in serious file corruption.  If you are
     * developing a program that makes use of TagLib from multiple processes you
     * must insure that you are only doing writes to a particular file from one
     * of them.
     */
    virtual bool save() = 0;

    /*!
     * Reads a block of size \a length at the current get pointer.
     */
    ByteVector readBlock(ulong length);

    /*!
     * Attempts to write the block \a data at the current get pointer.  If the
     * file is currently only opened read only -- i.e. readOnly() returns true --
     * this attempts to reopen the file in read/write mode.
     *
     * \note This should be used instead of using the streaming output operator
     * for a ByteVector.  And even this function is significantly slower than
     * doing output with a char[].
     */
    void writeBlock(const ByteVector &data);

    /*!
     * Returns the offset in the file that \a pattern occurs at or -1 if it can
     * not be found.  If \a before is set, the search will only continue until the
     * pattern \a before is found.  This is useful for tagging purposes to search
     * for a tag before the synch frame.
     *
     * Searching starts at \a fromOffset, which defaults to the beginning of the
     * file.
     *
     * \note This has the practial limitation that \a pattern can not be longer
     * than the buffer size used by readBlock().  Currently this is 1024 bytes.
     */
    long find(const ByteVector &pattern,
              long fromOffset = 0,
              const ByteVector &before = ByteVector::null);

    /*!
     * Returns the offset in the file that \a pattern occurs at or -1 if it can
     * not be found.  If \a before is set, the search will only continue until the
     * pattern \a before is found.  This is useful for tagging purposes to search
     * for a tag before the synch frame.
     *
     * Searching starts at \a fromOffset and proceeds from the that point to the
     * beginning of the file and defaults to the end of the file.
     *
     * \note This has the practial limitation that \a pattern can not be longer
     * than the buffer size used by readBlock().  Currently this is 1024 bytes.
     */
    long rfind(const ByteVector &pattern,
               long fromOffset = 0,
               const ByteVector &before = ByteVector::null);

    /*!
     * Insert \a data at position \a start in the file overwriting \a replace
     * bytes of the original content.
     *
     * \note This method is slow since it requires rewriting all of the file
     * after the insertion point.
     */
    void insert(const ByteVector &data, ulong start = 0, ulong replace = 0);

    /*!
     * Removes a block of the file starting a \a start and continuing for
     * \a length bytes.
     *
     * \note This method is slow since it involves rewriting all of the file
     * after the removed portion.
     */
    void removeBlock(ulong start = 0, ulong length = 0);

    /*!
     * Returns true if the file is read only (or if the file can not be opened).
     */
    bool readOnly() const;

    /*!
     * Since the file can currently only be opened as an argument to the
     * constructor (sort-of by design), this returns if that open succeeded.
     */
    bool isOpen() const;

    /*!
     * Returns true if the file is open and readble and valid information for
     * the Tag and / or AudioProperties was found.
     */
    bool isValid() const;

    /*!
     * Move the I/O pointer to \a offset in the file from position \a p.  This
     * defaults to seeking from the beginning of the file.
     *
     * \see Position
     */
    int seek(long offset, Position p = Beginning);

    /*!
     * Reset the end-of-file and error flags on the file.
     */
    void clear();

    /*!
     * Returns the current offset withing the file.
     */
    long tell() const;

    /*!
     * Returns the length of the file.
     */
    long length();

    /*!
     * Returns true if \a file can be opened for reading.  If the file does not
     * exist, this will return false.
     *
     * \deprecated
     */
    static bool isReadable(const char *file);

    /*!
     * Returns true if \a file can be opened for writing.
     *
     * \deprecated
     */
    static bool isWritable(const char *name);

    /*!
     * Adds \a resolver to the list of FileIOTypeResolvers used by TagLib.  Each
     * additional FileIOTypeResolver is added to the front of a list of
     * resolvers that are tried.  If the FileIOTypeResolver returns zero the
     * next resolver is tried.
     *
     * Returns a pointer to the added resolver (the same one that's passed in --
     * this is mostly so that static inialializers have something to use for
     * assignment).
     *
     * \see FileIOTypeResolver
     */
    static const FileIOTypeResolver *addFileIOTypeResolver(const FileIOTypeResolver *resolver);

    /*!
     * Removes \a resolver from the list of FileIOTypeResolvers used by TagLib.
     */
    static void removeFileIOTypeResolver(const FileIOTypeResolver *resolver);

  protected:
    /*!
     * Construct a File object without opening a file.  Allows object fields to
     * be set up before opening file.
     *
     * \note Constructor is protected since this class should only be
     * instantiated through subclasses.
     */
    File();

    /*!
     * Construct a File object and opens the \a file.  \a file should be a
     * be a C-string in the local file system encoding.
     *
     * \note Constructor is protected since this class should only be
     * instantiated through subclasses.
     */
    File(const char *file);

    /*!
     * Marks the file as valid or invalid.
     *
     * \see isValid()
     */
    void setValid(bool valid);

    /*!
     * Truncates the file to a \a length.
     */
    void truncate(long length);

    /*!
     * Returns the buffer size that is used for internal buffering.
     */
    static uint bufferSize();

  private:
    File(const File &);
    File &operator=(const File &);

    class FilePrivate;
    FilePrivate *d;
  };

}

#endif