# frozen_string_literal: true
require 'test_helper'
require 'tempfile'

class OptionsHelperTest < KubernetesDeploy::TestCase
  def test_missing_template_dir_no_extra_input
    assert_raises(KubernetesDeploy::OptionsHelper::OptionsError) do
      KubernetesDeploy::OptionsHelper.with_consolidated_template_dir([]) do
      end
    end
  end

  def test_no_template_dir_with_stdin
    old_stdin = $stdin

    input = Tempfile.open("kubernetes_deploy_test")
    fixture_path_entries = Dir.glob("#{fixture_path('hello-cloud')}/*.{yml,yaml}*")
    fixture_path_entries.each do |filename|
      File.open(filename, 'r') { |f| input.print(f.read) }
    end
    input.rewind
    $stdin = input

    KubernetesDeploy::OptionsHelper.with_consolidated_template_dir([]) do |template_dir|
      split_templates = File.read(
        File.join(template_dir, KubernetesDeploy::OptionsHelper::STDIN_TEMP_FILE)
      ).split("\n---\n")
      refute split_templates.empty?
      split_templates.each do |template|
        assert(YAML.safe_load(template))
      end
    end
  ensure
    $stdin = old_stdin
  end

  def test_template_dir_with_stdin
    old_stdin = $stdin

    input = Tempfile.open("kubernetes_deploy_test")
    fixture_path_entries = Dir.glob("#{fixture_path('hello-cloud')}/*.{yml,yaml}*")
    fixture_path_entries.each do |filename|
      File.open(filename, 'r') { |f| input.print(f.read) }
    end
    input.rewind
    $stdin = input

    KubernetesDeploy::OptionsHelper.with_consolidated_template_dir([fixture_path('hello-cloud')]) do |template_dir|
      split_templates = File.read(
        File.join(template_dir, KubernetesDeploy::OptionsHelper::STDIN_TEMP_FILE)
      ).split("\n---\n")
      refute split_templates.empty?
      split_templates.each do |template|
        assert(YAML.safe_load(template))
      end

      fixture_path_entries = Dir.entries(fixture_path('hello-cloud')).reject { |f| f =~ /^\.{1,2}$/ }
      template_dir_entries = Dir.entries(template_dir).reject do |f|
        f == KubernetesDeploy::OptionsHelper::STDIN_TEMP_FILE || f =~ /^\.{1,2}$/
      end

      refute(template_dir_entries.empty?)
      assert_equal(template_dir_entries.length, fixture_path_entries.length)
      fixture_path_entries.each do |fixture|
        template = template_dir_entries.find { |t| t.include?(fixture) }
        assert(template)
        assert_equal(
          YAML.safe_load(File.read(File.join(template_dir, template))),
          YAML.safe_load(File.read(File.join(fixture_path('hello-cloud'), fixture)))
        )
      end
    end
  ensure
    $stdin = old_stdin
  end

  def test_single_template_dir_only
    KubernetesDeploy::OptionsHelper.with_consolidated_template_dir([fixture_path('hello-cloud')]) do |template_dir|
      assert_equal(fixture_path('hello-cloud'), template_dir)
    end
  end

  def test_multiple_template_dirs
    template_dirs = [fixture_path('hello-cloud'), fixture_path('partials')]
    KubernetesDeploy::OptionsHelper.with_consolidated_template_dir(template_dirs) do |template_dir|
      fixture_path_entries = template_dirs.collect { |dir| Dir.entries(dir) }.flatten.uniq
      template_dir_entries = Dir.entries(template_dir)
      assert_equal(fixture_path_entries.length, template_dir_entries.length)
      fixture_path_entries.each do |fixture|
        next if fixture =~ /^\.{1,2}$/
        assert template_dir_entries.index { |s| s.include?(fixture) }
      end
    end
  end
end
