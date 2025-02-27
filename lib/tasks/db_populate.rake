namespace :db do
  desc "Populate the database with initial course data from the OSU Classes API"
  task populate: :environment do
    unless User.exists?(role: "Admin")
      User.create(
        email: "admin@osu.edu",
        password: "password",
        first_name: "Admin",
        last_name: "Admin",
        role: "Admin",
        is_approved: true
      )
      puts "Default admin user created! Email: admin@osu.edu, Password: password"
    end
    terms = { '1232' => 'Spring 2023', '1234' => 'Summer 2023', '1238' => 'Autumn 2023' }
    terms.each do |term_code, term_name|
      api_service = ApiService.new
      search_params = {
        q: 'cse',
        campus: 'col',
        term: term_code
      }

      response = api_service.courses(search_params)

      courses = response.dig('data', 'courses')
      
      courses&.each do |course|
        name = course.dig('course', 'title')
        course_number = course.dig('course', 'catalogNumber')
        subject = course.dig('course', 'subject')
        description = course.dig('course', 'description')
        short_description = course.dig('course', 'shortDescription')
        level = course.dig('course', 'catalogLevel')
        term_courses = term_code

        course_entry = Course.find_or_initialize_by(course_number: course_number, term: term_code)
        course_entry.update(
          name:,
          course_number:,
          subject:,
          description:,
          short_description:,
          level:,
          term: term_courses,
        )

        sections = course['sections']
        sections&.each do |section|
          section_number = section['classNumber']
          term_sections = term_code
          instruction_mode = section['instructionMode']

          days_hash = { monday: 'Monday', tuesday: 'Tuesday', wednesday: 'Wednesday', thursday: 'Thursday', friday: 'Friday' }
          days = ""
          start_time = ""
          end_time = ""
          instructor = ""

          # Populate days
          meetings = section['meetings']
          meetings&.each do |meeting|
            days_hash.each do |day, day_name|
              days += "#{day_name}, " if meeting[day.to_s]
              start_time = meeting['startTime']
              end_time = meeting['endTime']
            end
            # Populate instructor
            instructors = meeting['instructors']
            instructors&.each do |single_instructor|
              instructor += "#{single_instructor['email']}, "
            end
          end
          instructor = instructor.chomp(', ')
          days = days.chomp(', ')



          start_time = start_time.nil? ? nil : Time.parse(start_time)
          end_time = end_time.nil? ? nil : Time.parse(end_time)

          section_entry = course_entry.sections.find_or_initialize_by(section_number: section_number, term: term_code)
          section_entry.update(
            section_number:,
            term: term_courses,
            instruction_mode:,
            days:,
            start_time:,
            end_time:,
            instructor:
          )
        end
      end
    end
  end
end
