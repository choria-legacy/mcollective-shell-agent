require 'spec_helper'
require 'mcollective/agent/shell/job'

module MCollective
  module Agent
    class Shell
      describe Job do
        before :each do
          @tmpdir = Dir.mktmpdir
          Shell::Job.stubs(:state_path).returns(@tmpdir)
        end

        after :each do
          FileUtils.remove_entry_secure @tmpdir
        end

        describe 'list' do
          it 'should return nothing when no jobs are created' do
            Job.list.should == []
          end

          it 'should return two jobs when two are made' do
            one = Job.new
            two = Job.new
            jobs = Job.list
            jobs.size.should == 2
            jobs[0].class.should == Job
            jobs[1].class.should == Job
          end
        end

        describe '#initialize' do
          it 'should use the handle if passed' do
            job = Job.new('made-up-handle')
            job.handle.should == 'made-up-handle'
          end

          it 'should generate a handle if none is specified' do
            job = Job.new
            job.handle.should =~ /[A-Z0-9-]+/
          end
        end

        describe '#start_command' do
          it 'should write files, spawn, and check for starting' do
            job = Job.new
            state_directory = job.send(:state_directory)
            job.stubs(:find_ruby).returns('testing-ruby')
            File.expects(:open).with("#{state_directory}/command", 'w')
            File.expects(:open).with("#{state_directory}/wrapper", 'w')
            Process.expects(:spawn).with('testing-ruby', "#{state_directory}/wrapper", {
              :chdir => '/',
              :in => :close,
              :out => :close,
              :err => :close,
            }).returns(53)
            File.expects(:exists?).with("#{state_directory}/pid").returns(true).twice
            IO.expects(:read).with("#{state_directory}/pid").returns("54\n")
            job.start_command('echo foo')
            job.pid.should == 54

            # explicitly unstub so the after block can fire
            File.unstub(:open)
          end
        end

        describe '#stdout' do
          it 'should default to an offset of zero' do
            job = Job.new
            state_directory = job.send(:state_directory)

            filehandle = mock('filehandle')
            File.expects(:new).with("#{state_directory}/stdout", 'rb').returns(filehandle)
            filehandle.expects(:seek).with(0, IO::SEEK_SET)
            filehandle.expects(:read).returns("some data")
            filehandle.expects(:close)
            job.stdout.should == "some data"
          end

          it 'should read from an offset' do
            job = Job.new
            state_directory = job.send(:state_directory)

            filehandle = mock('filehandle')
            File.expects(:new).with("#{state_directory}/stdout", 'rb').returns(filehandle)
            filehandle.expects(:seek).with(5, IO::SEEK_SET)
            filehandle.expects(:read).returns("some data at an offset")
            filehandle.expects(:close)
            job.stdout(5).should == "some data at an offset"
          end
        end

        describe '#stderr' do
          it 'should default to an offset of zero' do
            job = Job.new
            state_directory = job.send(:state_directory)

            filehandle = mock('filehandle')
            File.expects(:new).with("#{state_directory}/stderr", 'rb').returns(filehandle)
            filehandle.expects(:seek).with(0, IO::SEEK_SET)
            filehandle.expects(:read).returns("some data")
            filehandle.expects(:close)
            job.stderr.should == "some data"
          end

          it 'should read from an offset' do
            job = Job.new
            state_directory = job.send(:state_directory)

            filehandle = mock('filehandle')
            File.expects(:new).with("#{state_directory}/stderr", 'rb').returns(filehandle)
            filehandle.expects(:seek).with(5, IO::SEEK_SET)
            filehandle.expects(:read).returns("some data at an offset")
            filehandle.expects(:close)
            job.stderr(5).should == "some data at an offset"
          end
        end

        describe '#status' do
          let(:job) do
            test_job = Job.new
            test_job.stubs(:state_directory).returns('test')
            test_job
          end

          it 'should be :failed if there is an error file' do
            File.expects(:exists?).with('test/error').returns(true)
            job.status.should == :failed
          end

          it 'should be :starting if there is no pid' do
            File.expects(:exists?).with('test/error').returns(false)
            File.expects(:exists?).with('test/pid').returns(false)
            job.status.should == :starting
          end

          it 'should be :stopped is there is an exitstatus' do
            File.expects(:exists?).with('test/error').returns(false)
            File.expects(:exists?).with('test/pid').returns(true)
            File.expects(:exists?).with('test/exitstatus').returns(true)
            job.status.should == :stopped
          end

          it 'should be :running if there is no exitstatus' do
            File.expects(:exists?).with('test/error').returns(false)
            File.expects(:exists?).with('test/pid').returns(true)
            File.expects(:exists?).with('test/exitstatus').returns(false)
            job.status.should == :running
          end
        end

        describe '#kill' do
          it 'should send TERM to the pid' do
            job = Job.new
            job.stubs(:pid).returns(58)
            Process.expects(:kill).with('TERM', 58)
            job.kill
          end
        end

        describe '#wait_for_process' do
          it 'should not loop if process is not :running' do
            job = Job.new
            job.expects(:status).returns(:stopped)
            job.expects(:sleep).never
            job.wait_for_process
          end

          it 'should sleep and loop if status is :running' do
            job = Job.new
            job.stubs(:status).returns(:running, :stopped)
            job.expects(:sleep).with(0.1).once
            job.wait_for_process
          end
        end

        describe '#cleanup_state' do
          it 'should blow away the state directory' do
            job = Job.new
            job.stubs(:state_directory).returns('test')
            FileUtils.expects(:remove_entry_secure).with('test')
            job.cleanup_state

            # explicitly unstub so the after block can fire
            FileUtils.unstub(:remove_entry_secure)
          end
        end
      end
    end
  end
end
